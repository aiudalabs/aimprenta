#!/usr/bin/env bash
# aimprenta installer — reproduces the full 3-command book pipeline on any machine.
# Idempotent: existing installs are skipped unless --force. Test with CLAUDE_DIR=/tmp/x ./install.sh
#
# Self-contained: 9 of 11 upstream dependencies are vendored under vendor/ in
# this repo (permissive license, see vendor/NOTICE.md) and installed with zero
# network calls. Only 2 — sciwrite and kindle-cover (unclear/absent upstream
# license) — are cloned fresh from GitHub at their pinned SHA, same as before.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
SKILLS="$CLAUDE_DIR/skills"
AGENTS="$CLAUDE_DIR/agents"
VENDOR="$HERE/vendor"                    # self-contained, checked into this repo
LIVE="$SKILLS/_vendor"                   # git-clone-at-install, sciwrite + kindle-cover only
VENV="$CLAUDE_DIR/venvs/aimprenta"
FORCE=0
[ "${1:-}" = "--force" ] && FORCE=1
[ "${1:-}" = "--check" ] && { bash "$HERE/scripts/doctor.sh"; exit $?; }

log()  { printf '\033[32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33mwarn\033[0m %s\n' "$*"; }

install_dir() { # $1 src dir, $2 dest dir
  if [ -d "$2" ] && [ "$FORCE" = 0 ]; then warn "exists, skipped: $2"; return 1; fi
  rm -rf "$2"; mkdir -p "$(dirname "$2")"; cp -R "$1" "$2"
}

mkdir -p "$SKILLS" "$AGENTS" "$LIVE" "$CLAUDE_DIR/principles" "$CLAUDE_DIR/venvs"

# ── 1. Live-clone the 2 unclear-license vendors (pinned SHA) ────────────────
log "Cloning live-clone vendors (pinned, unclear upstream license — see vendor/NOTICE.md)"
grep -A2 '^# --- LIVE-CLONE' "$HERE/vendors.lock" | grep -v '^#' | while read -r url sha name; do
  [ -z "$name" ] && continue
  d="$LIVE/$name"
  if [ ! -d "$d/.git" ]; then
    git clone -q "$url" "$d"
  fi
  git -C "$d" fetch -q origin "$sha" 2>/dev/null || git -C "$d" fetch -q origin
  git -C "$d" checkout -q "$sha"
  echo "  $name @ ${sha:0:10}"
done

# ── 2. Orchestrators (this repo's own skills) ───────────────────────────────
log "Installing orchestrator skills"
for s in book-author scientific-book-editor production-book-publisher \
         paper-author paper-publisher article-author; do
  install_dir "$HERE/skills/$s" "$SKILLS/$s" && echo "  $s" || true
done

# ── 3. sciwrite (whole vendor clone IS the skill; live-clone) ───────────────
install_dir "$LIVE/sciwrite" "$SKILLS/sciwrite" && echo "  sciwrite" || true

# ── 4. research-skills: paper-review + drafting set (vendored) ──────────────
log "Installing research-skills set (vendored)"
RS="$VENDOR/research-skills/plugins/manuscript"
install_dir "$RS/skills/paper-review" "$SKILLS/paper-review" || true
install_dir "$RS/skills/humanizer"    "$SKILLS/humanizer"    || true
install_dir "$RS/skills/lit-review"   "$SKILLS/lit-review"   || true
if install_dir "$RS/skills/manuscript-writing" "$SKILLS/manuscript-drafting"; then
  sed -i.bak 's/^name: manuscript-writing/name: manuscript-drafting/' "$SKILLS/manuscript-drafting/SKILL.md" && rm -f "$SKILLS/manuscript-drafting/SKILL.md.bak"
fi
cp "$RS/agents/paper-review.md" "$AGENTS/paper-review.md"

# ── 5. citation-audit (vendored, patched: Codex MCP → Claude subagents) ─────
log "Installing citation-audit (vendored, adapted)"
AH="$VENDOR/academic-human-in-the-loop"
if [ ! -d "$SKILLS/citation-audit" ] || [ "$FORCE" = 1 ]; then
  rm -rf "$SKILLS/citation-audit"
  mkdir -p "$SKILLS/citation-audit/tools"
  cp "$AH/skills/citation-audit/SKILL.md" "$SKILLS/citation-audit/SKILL.md"
  cp -R "$AH/skills/shared-references" "$SKILLS/citation-audit/shared-references"
  cp "$AH/tools/verify_paper_audits.sh" "$AH/tools/refresh_audit_hashes.py" "$SKILLS/citation-audit/tools/" 2>/dev/null || true
  sed -i.bak \
    -e 's|(\.\./shared-references/|(shared-references/|g' \
    -e 's|allowed-tools: Bash(\*), Read, Grep, Glob, Edit, Write, mcp__codex__codex, WebSearch, WebFetch|allowed-tools: Bash(*), Read, Grep, Glob, Edit, Write, Agent, WebSearch, WebFetch|' \
    "$SKILLS/citation-audit/SKILL.md" && rm -f "$SKILLS/citation-audit/SKILL.md.bak"
  python3 - "$SKILLS/citation-audit/SKILL.md" "$HERE/patches/citation-audit-adaptation.md" <<'PY'
import sys
from pathlib import Path
p, note = Path(sys.argv[1]), Path(sys.argv[2]).read_text()
parts = p.read_text().split("---\n", 2)
p.write_text(parts[0] + "---\n" + parts[1] + "---\n\n" + note + "\n" + parts[2])
PY
  echo "  citation-audit (Codex→Claude patch + bundled shared-references)"
fi

# ── 6. standalone manuscript-writing → manuscript-revision (vendored) ───────
if [ ! -d "$SKILLS/manuscript-revision" ] || [ "$FORCE" = 1 ]; then
  rm -rf "$SKILLS/manuscript-revision"; mkdir -p "$SKILLS/manuscript-revision"
  cp "$VENDOR/manuscript-writing/SKILL.md" "$SKILLS/manuscript-revision/SKILL.md"
  cp -R "$VENDOR/manuscript-writing/references" "$SKILLS/manuscript-revision/references"
  sed -i.bak 's/^name: manuscript-writing/name: manuscript-revision/' "$SKILLS/manuscript-revision/SKILL.md" && rm -f "$SKILLS/manuscript-revision/SKILL.md.bak"
  echo "  manuscript-revision (renamed from standalone manuscript-writing)"
fi

# ── 7. line-and-copy-editor (vendored) ───────────────────────────────────────
install_dir "$VENDOR/claude-skills/line-and-copy-editor" "$SKILLS/line-and-copy-editor" || true

# ── 8. book-typesetting via its own installer (vendored) ────────────────────
log "Installing book-typesetting (vendored, own INSTALL.sh)"
if [ ! -d "$SKILLS/book-typesetting" ] || [ "$FORCE" = 1 ]; then
  BT_FLAGS="--dir $SKILLS/book-typesetting"
  [ "$FORCE" = 1 ] && BT_FLAGS="$BT_FLAGS --force"
  ( cd "$VENDOR/book-typesetting-skill" && bash INSTALL.sh $BT_FLAGS >/dev/null ) \
    || { rm -rf "$SKILLS/book-typesetting"; cp -R "$VENDOR/book-typesetting-skill" "$SKILLS/book-typesetting"; rm -rf "$SKILLS/book-typesetting/.git"; }
  echo "  book-typesetting"
fi

# ── 9. kindle-book (vendored) / kindle-cover (live-clone + local patch) ─────
if [ ! -d "$SKILLS/kindle-book" ] || [ "$FORCE" = 1 ]; then
  rm -rf "$SKILLS/kindle-book"; mkdir -p "$SKILLS/kindle-book"
  for d in SKILL.md scripts assets references; do cp -R "$VENDOR/kindle-book-skill/$d" "$SKILLS/kindle-book/"; done
fi
if [ ! -d "$SKILLS/kindle-cover" ] || [ "$FORCE" = 1 ]; then
  rm -rf "$SKILLS/kindle-cover"; mkdir -p "$SKILLS/kindle-cover"
  cp "$LIVE/kindle-cover-skill/SKILL.md" "$SKILLS/kindle-cover/"
  cp -R "$LIVE/kindle-cover-skill/scripts" "$SKILLS/kindle-cover/"
  # Local patch: add 7x10in trim (upstream only ships 5x8/5.5x8.5/6x9/8.5x11).
  # See patches/kindle-cover-trim-7x10.md. Additive, idempotent.
  python3 - "$SKILLS/kindle-cover/scripts/generate_cover.py" <<'PY'
import sys
from pathlib import Path
p = Path(sys.argv[1])
s = p.read_text()
needle = '"6x9":     {"w": 6.0,  "h": 9.0},\n'
patch = '    "7x10":    {"w": 7.0,  "h": 10.0},\n'
if patch.strip() not in s and needle in s:
    s = s.replace(needle, needle + patch)
    p.write_text(s)
PY
fi
echo "  kindle-book (vendored) · kindle-cover (live-clone + 7x10 trim patch)"

# ── 10. KDP skills (vendored; docs bundled, plugin-root refs rewritten) ─────
log "Installing KDP skills (vendored)"
for k in kdp-audit kdp-listing; do
  if [ ! -d "$SKILLS/$k" ] || [ "$FORCE" = 1 ]; then
    rm -rf "$SKILLS/$k"
    cp -R "$VENDOR/claude-anvil/kdp/skills/$k" "$SKILLS/$k"
    cp -R "$VENDOR/claude-anvil/kdp/docs" "$SKILLS/$k/docs"
    sed -i.bak 's|${CLAUDE_PLUGIN_ROOT}/docs|docs|g' "$SKILLS/$k/SKILL.md" && rm -f "$SKILLS/$k/SKILL.md.bak"
    echo "  $k"
  fi
done
# NOTE: kdp-publish and the kdp-cover MCP are deliberately NOT installed (OpenAI API dependency).

# ── 11. ebook-publishing (vendored) ──────────────────────────────────────────
if [ ! -d "$SKILLS/ebook-publishing" ] || [ "$FORCE" = 1 ]; then
  rm -rf "$SKILLS/ebook-publishing"; mkdir -p "$SKILLS/ebook-publishing"
  cp "$VENDOR/ebook-publishing-skill/SKILL.md" "$SKILLS/ebook-publishing/"
  cp -R "$VENDOR/ebook-publishing-skill/references" "$SKILLS/ebook-publishing/"
  echo "  ebook-publishing"
fi

# ── 12. bookwright (3 skills, vendored) ──────────────────────────────────────
log "Installing bookwright skills (vendored)"
for k in textbook-methodology notebook-paired-with-prose cross-reference-discipline; do
  install_dir "$VENDOR/claude-anvil/bookwright/skills/$k" "$SKILLS/$k" && echo "  $k" || true
done

# ── 13. Agents (academic ×12 + bookwright ×11, vendored) + principles ───────
log "Installing agents (vendored)"
cp "$VENDOR/academic-writing-agents/principles/academic-writing.md" "$CLAUDE_DIR/principles/"
n=0
for f in "$VENDOR/academic-writing-agents/agents/"*.md "$VENDOR/claude-anvil/bookwright/agents/"*.md; do
  b="$(basename "$f")"
  if [ -e "$AGENTS/$b" ] && [ "$FORCE" = 0 ]; then continue; fi
  cp "$f" "$AGENTS/$b"
  # upstream hardcodes its author's home path in the academic agents
  sed -i.bak "s|/Users/owl/.claude|$CLAUDE_DIR|g" "$AGENTS/$b" && rm -f "$AGENTS/$b.bak"
  n=$((n+1))
done
echo "  $n agent files installed/updated"

# ── 14. Deterministic gate scripts — installed, not just in this clone ──────
# These are referenced by scientific-book-editor and production-book-publisher
# from an absolute path so they keep working after the clone is deleted.
log "Installing gate scripts (~/.claude/scripts/aimprenta)"
mkdir -p "$CLAUDE_DIR/scripts/aimprenta"
cp "$HERE/scripts/check_structure.py" "$HERE/scripts/check_readability.py" "$HERE/scripts/check_claims.py" "$CLAUDE_DIR/scripts/aimprenta/"
echo "  check_structure.py check_readability.py check_claims.py"

# ── 15. Python venv for production helpers ──────────────────────────────────
log "Python venv ($VENV)"
if command -v uv >/dev/null; then
  [ -d "$VENV" ] || uv venv -q "$VENV"
  VIRTUAL_ENV="$VENV" uv pip install -q pydantic pytest reportlab Pillow pypdf fonttools pyyaml
else
  [ -d "$VENV" ] || python3 -m venv "$VENV"
  "$VENV/bin/pip" install -q pydantic pytest reportlab Pillow pypdf fonttools pyyaml
fi
echo "  pydantic pytest reportlab Pillow pypdf fonttools pyyaml"

# ── 16. Doctor ──────────────────────────────────────────────────────────────
log "Toolchain check"
bash "$HERE/scripts/doctor.sh" || true

log "Done. New Claude Code sessions will see the skills. Workflows:"
echo 'Books:'
echo '  /book-author "an idea"          → book/ + SYLLABUS.md + METADATA.md'
echo '  /scientific-book-editor ./book/ → 5 reports + verdict + revised-book/'
echo '  /production-book-publisher ./revised-book/ → dist/{ebook,paperback,validation}'
echo
echo 'Papers:'
echo '  /paper-author "a research question" → manuscript.md + references.bib'
echo '  /paper-publisher <paper-dir>        → submission/{paper.pdf, validation}'
echo
echo 'Short-form articles (LinkedIn/Medium/blog/newsletter):'
echo '  /article-author "an angle" → article.md + formatted/{platform}.md'
echo
echo 'Optional, not installed by this script (see vendor/NOTICE.md + docs/optional-skills.md):'
echo '  scientific-manuscript-review — npx skills add <source> --skill scientific-manuscript-review'
echo '  archify / diagram-design     — see docs/diagrams.md'
