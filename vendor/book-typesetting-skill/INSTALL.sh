#!/usr/bin/env bash
# Installer for the book-typesetting skill.
#
#   ./INSTALL.sh                 install for Claude Code (~/.claude/skills)
#   ./INSTALL.sh --agents        install to ~/.agents/skills (cross-runtime)
#   ./INSTALL.sh --dir PATH      install into a specific skills directory
#   ./INSTALL.sh --force         replace an existing install (a backup is kept)
#   ./INSTALL.sh --check         only report whether the toolchain is ready
#
# You can equally just clone straight into place:
#   git clone <repo-url> ~/.claude/skills/book-typesetting
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAME="book-typesetting"
DEST_ROOT="$HOME/.claude/skills"
FORCE=0
CHECK_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agents) DEST_ROOT="$HOME/.agents/skills"; shift ;;
    --dir) DEST_ROOT="$2"; shift 2 ;;
    --force) FORCE=1; shift ;;
    --check) CHECK_ONLY=1; shift ;;
    -h|--help) sed -n '2,11p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

[[ -f "$SRC/SKILL.md" ]] || { echo "error: run this from inside the repo" >&2; exit 1; }

if [[ "$CHECK_ONLY" == 1 ]]; then
  exec bash "$SRC/scripts/doctor.sh"
fi

DEST="$DEST_ROOT/$NAME"

if [[ -e "$DEST" ]]; then
  if [[ "$FORCE" != 1 ]]; then
    echo "error: $DEST already exists."
    echo "       Re-run with --force to replace it (the old copy is backed up)."
    exit 1
  fi
  BACKUP="$DEST.backup-$(date +%Y%m%d-%H%M%S)"
  mv "$DEST" "$BACKUP"
  echo "backed up existing install -> $BACKUP"
fi

mkdir -p "$DEST"
# Copy the skill itself; leave repo furniture behind.
tar -C "$SRC" -cf - \
    --exclude '.git' --exclude '.github' --exclude '__pycache__' \
    --exclude '.DS_Store' --exclude 'INSTALL.sh' --exclude 'README.md' \
    --exclude 'LICENSE' --exclude 'NOTICE.md' --exclude '.gitignore' \
    . | tar -C "$DEST" -xf -

chmod +x "$DEST"/scripts/*.sh "$DEST"/scripts/*.py 2>/dev/null || true

SHOWN="${DEST/#$HOME/\~}"
echo "INSTALLED -> $SHOWN"
echo
echo "Now checking the toolchain (this does not affect the install)..."
echo
set +e
bash "$DEST/scripts/doctor.sh"
DOCTOR=$?
set -e

echo
echo "------------------------------------------------------------------------"
if [[ "$DOCTOR" != 0 ]]; then
  cat <<EOF
The skill is installed, but the toolchain above is INCOMPLETE. Install the
tools marked MISS, then re-check with:

  $SHOWN/scripts/doctor.sh

EOF
fi
cat <<EOF
In Claude Code, ask for anything book-typesetting related and the skill loads
itself. To read it directly: $SHOWN/SKILL.md

Start a book from nothing:
  $SHOWN/scripts/init-book.sh \\
      --title "My Book" --author "A. Writer" --trim 6x9 --columns 1 ./my-book
  cd my-book/typesetting && quarto render book-print.qmd --to pdf

Import an existing Word manuscript:
  $SHOWN/scripts/import-docx.py manuscript.docx --target ./my-book --dry-run

New to print? Read $SHOWN/reference/print-basics.md first.

NOTE: no CMYK ICC profile ships with this repo (see NOTICE.md). press-pdf.sh
finds one automatically on most machines; if it cannot, it tells you how.

Uninstall: rm -rf "$SHOWN"
------------------------------------------------------------------------
EOF

exit 0
