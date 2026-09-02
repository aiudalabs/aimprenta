# book-typesetting

A [Claude Code](https://claude.com/claude-code) skill that turns a manuscript into
press-ready book files: a print interior built from markdown, a wraparound cover,
and the CMYK PDF/X-1a conversion that IngramSpark, Amazon KDP and other
print-on-demand services require.

Extracted from a book that shipped in both hardcover and paperback, then
generalised and tested against fresh manuscripts.

```bash
git clone https://github.com/yoelf22/book-typesetting-skill.git ~/.claude/skills/book-typesetting
~/.claude/skills/book-typesetting/scripts/doctor.sh     # check your toolchain
```

Then, in Claude Code, describe what you want — *"typeset my book for KDP"*, *"the
printer rejected my cover"*, *"convert this PDF to CMYK"* — and the skill loads
itself.

---

## What it does

| | |
|---|---|
| **Scaffold** | `init-book.sh` creates a complete project — master `.qmd` with the full LaTeX preamble, Lua filter chain, starter chapter — that renders to a real book PDF immediately |
| **Import** | `import-docx.py` converts a Word manuscript: splits it into chapters, redistributes footnotes, lifts figure captions out of alt text, renames media |
| **Layout** | One- or two-column interiors, mirrored margins, pooled footnotes, full-width tables and figure bands, index, QR boxes |
| **Press prep** | `press-pdf.sh` produces CMYK PDF/X-1a:2001 with an embedded profile, TrimBox and no annotations |
| **Verify** | `verify-pdfx.py` pre-flights a file against what uploaders actually reject. **Exit 1 means don't upload** |
| **Covers** | `cover-render.sh` takes an Inkscape SVG to a press-ready wraparound cover plus a proof image |

## Why it exists

Print uploaders reject files *silently*, or with messages pointing at the wrong
problem. A cover once came back as **"COVER ELEMENTS OUTSIDE SAFETY AREA"** when
the real fault was that the document had been built to the wrong trim size
entirely. `verify-pdfx.py` prints the file's actual geometry, so that class of
mistake surfaces in one line instead of three days later.

It also fixes a trap in the standard Ghostscript recipe. Given a file that still
carries annotations — which every Quarto interior does, because `hyperref` turns
cross-references and URLs into them — Ghostscript **silently abandons PDF/X mode**
and mentions it only in passing, while the prologue's pdfmarks still stamp the
file as PDF/X-1a. The result claims conformance it never had. This pipeline
strips annotations *before* conversion so that cannot happen.

## Install

```bash
# Straight into place
git clone https://github.com/yoelf22/book-typesetting-skill.git ~/.claude/skills/book-typesetting

# Or clone anywhere and run the installer
git clone https://github.com/yoelf22/book-typesetting-skill.git
cd book-typesetting-skill && ./INSTALL.sh
```

| Command | Effect |
|---|---|
| `./INSTALL.sh` | install for Claude Code (`~/.claude/skills`) |
| `./INSTALL.sh --agents` | install to `~/.agents/skills` (Codex, Gemini CLI, Copilot CLI) |
| `./INSTALL.sh --dir PATH` | install into a specific skills directory |
| `./INSTALL.sh --force` | replace an existing install (old copy backed up) |
| `./INSTALL.sh --check` | toolchain report only |

Uninstall: `rm -rf ~/.claude/skills/book-typesetting`. Nothing outside the skill
directory is modified and no config files are edited.

## Requirements

macOS or Linux. Run `scripts/doctor.sh` for a precise report.

| Tool | For | Install (macOS) |
|---|---|---|
| **Quarto** | rendering markdown → PDF | `brew install --cask quarto` |
| **LaTeX** | the PDF engine Quarto drives | `quarto install tinytex` |
| **Ghostscript** | RGB → CMYK PDF/X-1a | `brew install ghostscript` |
| **Python 3** | PDF surgery and verification | preinstalled |
| **pandoc** | Word import (ships with Quarto) | `brew install pandoc` |
| Inkscape | **covers only** | `brew install --cask inkscape` |
| poppler | proof images, page counts | `brew install poppler` |

`pikepdf` is fetched on demand via `uv` if not installed.

Two things that catch people out:

- `quarto install tinytex` puts LaTeX somewhere **not on `PATH`**. That's expected —
  Quarto finds it, and so does `doctor.sh`. An empty `which xelatex` is not a problem.
- **Inkscape has no substitute for covers.** rsvg, cairosvg and ImageMagick
  silently drop SVG flowed text, yielding a cover with the back-cover blurb
  missing and no error.

## Quick start

```bash
S=~/.claude/skills/book-typesetting

# A rendering book project from nothing
$S/scripts/init-book.sh --title "My Book" --author "A. Writer" \
    --trim 6x9 --columns 1 ./my-book
cd my-book/typesetting && quarto render book-print.qmd --to pdf

# Or start from a Word manuscript
$S/scripts/import-docx.py manuscript.docx --target ./my-book --dry-run

# Make it press-ready, then check it before uploading
$S/scripts/press-pdf.sh --title "My Book" _output/book-print.pdf _output/press.pdf
$S/scripts/verify-pdfx.py _output/press.pdf --expect-size 6x9 --expect-pages 130
```

Every script takes `--help`.

## Documentation

| File | |
|---|---|
| [`SKILL.md`](SKILL.md) | how the skill routes work |
| [`reference/getting-started.md`](reference/getting-started.md) | prerequisites: tools, printer accounts, ISBNs, decisions to make first |
| [`reference/print-basics.md`](reference/print-basics.md) | trim, bleed, spine, CMYK, PDF/X — **no prior knowledge assumed** |
| [`reference/input-contract.md`](reference/input-contract.md) | what your markdown and images must look like |
| [`reference/quarto-layout.md`](reference/quarto-layout.md) | the interior layout and its Lua filter chain |
| [`reference/galley-recipe.md`](reference/galley-recipe.md) | one chapter → standalone proof PDF |
| [`reference/press-pdfx.md`](reference/press-pdfx.md) | RGB → CMYK PDF/X-1a in depth |
| [`reference/cover-geometry.md`](reference/cover-geometry.md) | cover templates, safe areas, Inkscape pipeline |

**Never produced a print book?** Start with `reference/print-basics.md`. Most
mistakes come from not knowing what the printer is asking for, not from getting a
command wrong.

## Colour profiles

**No ICC profile ships with this repository.** US services expect *U.S. Web Coated
(SWOP) v2*, which is Adobe's and not ours to redistribute. `press-pdf.sh` finds
one automatically — `--icc`, then `assets/swop.icc`, then a system Adobe install,
then Ghostscript's `default_cmyk.icc` with a warning — and tells you how to get
one if it can't. See [`NOTICE.md`](NOTICE.md).

## Licence

MIT — see [`LICENSE`](LICENSE).
