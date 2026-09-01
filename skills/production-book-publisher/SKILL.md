---
name: production-book-publisher
description: >
  Production and publishing pipeline for a finished book manuscript. Takes a
  canonical markdown/Quarto book source and produces print-ready interiors
  (paperback + hardcover PDF via Quarto/LaTeX), a validated EPUB3 for Kindle,
  full-wrap covers with computed spine width, a KDP compliance audit, and
  multi-platform distribution checklists. Use when the user says
  "/production-book-publisher", "build the book formats", "make the epub and
  print PDF", "prepare for KDP", "publish my book", or after
  scientific-book-editor has produced an approved revised-book/. Editorial QA
  is NOT this skill — use scientific-book-editor for that.
argument-hint: "[book-source-dir] [output-dir]"
---

# Production Book Publisher — Steps 7–11 Orchestrator

Input: a canonical book source directory (markdown chapters; front matter or a
metadata file with title/author/subtitle if available). Output tree (created
under `<output-dir>`, default `<book-dir>/../dist`):

```
dist/
├── ebook/
│   └── book.epub
├── paperback/
│   ├── interior.pdf
│   └── cover.pdf
├── hardcover/
│   ├── interior.pdf
│   └── cover.pdf
└── validation/
    ├── epubcheck.txt
    ├── pdf-preflight.txt
    └── kdp-audit.md
```

**Metadata rule (hard):** title, subtitle, author, ISBN, trim size, price come
from the book's front matter, a metadata file, or the user — NEVER invented. If
absent, ask; a missing ISBN is fine (KDP assigns one) but must be reported as
absent, not filled with a placeholder.

**Non-clobber rule:** if the output dir already contains a build, list what is
there and confirm before overwriting.

## Prerequisites (verify before starting, report gaps)

Run `bash ~/.claude/skills/book-typesetting/scripts/doctor.sh` — needs quarto,
pandoc, ghostscript, python; xelatex for the kindle-book print path; epubcheck
for validation. `kindle-cover`'s script needs a python with `reportlab` and
`Pillow` (a venv works: invoke the script with that venv's python). Missing
tools: report and continue with the steps that can run.

## Step 7 — Print interiors (`book-typesetting` skill)

Invoke `book-typesetting` for the print interior via Quarto/LaTeX:

- **Paperback:** 6×9 in trim (or the user's/metadata trim).
- **Hardcover:** 6.14×9.21 in trim (case-laminate standard) unless specified.
- Assemble chapters in order (respect any syllabus/ordering file in the source;
  otherwise lexical `ch*` order). Use the skill's templates
  (`assets/templates/book-print.qmd.tmpl`, `quarto.yml.tmpl`) and its Lua
  filters. For press-ready CMYK PDF/X-1a (IngramSpark), use
  `scripts/press-pdf.sh`; for KDP, standard PDF with embedded fonts suffices.
- Outputs: `paperback/interior.pdf`, `hardcover/interior.pdf`.
- Record each interior's final page count — Step 9 needs it for spine width.

## Step 8 — EPUB3 (`kindle-book` skill)

Invoke `kindle-book`: its `scripts/build_kindle.py` converts the concatenated
markdown to EPUB3 (pandoc) with `assets/epub-styles.css`. Output
`ebook/book.epub`.

Then validate: `epubcheck ebook/book.epub > validation/epubcheck.txt 2>&1`.
Errors are blocking for store upload; warnings go in the report. Fix
structural errors (bad nesting, missing metadata) and re-run until clean or
until remaining items need author input.

## Step 9 — Covers (`kindle-cover` skill)

Invoke `kindle-cover` per format: `scripts/generate_cover.py` computes spine
width from page count and paper type and lays out back + spine + front with
bleed. One cover per trim/page-count pair:

- `paperback/cover.pdf` (paperback page count)
- `hardcover/cover.pdf` (hardcover page count; if the printer's hardcover
  template differs — IngramSpark wraps need larger boards — say so in the
  validation report rather than pretending the KDP formula covers it)

Front cover artwork: use the book's existing cover asset if the source has
one; otherwise generate a clean typographic front (title/subtitle/author from
metadata) — never stock images with unknown licenses.

## Step 10 — Preflight + KDP audit

- PDF preflight: `book-typesetting`'s `scripts/verify-pdfx.py` (plus
  `pdfinfo`/ghostscript checks: page size = trim, fonts embedded, no
  annotations) over both interiors and covers →
  `validation/pdf-preflight.txt`.
- Invoke `kdp-audit` over the manuscript + built artifacts + metadata →
  `validation/kdp-audit.md` (Critical vs Warnings gap report).

**Gate:** Critical findings must be either fixed and re-built, or explicitly
accepted by the user, before Step 11.

## Step 11 — Distribution (`ebook-publishing` skill)

Invoke `ebook-publishing` to produce `validation/distribution-checklist.md`:
per-platform readiness (KDP, Kobo, Apple Books, Google Play, IngramSpark,
B&N, Draft2Digital) — what each needs beyond the built files, ISBN strategy,
pricing/royalty notes, and the exact upload order. This step produces
checklists and listing copy (optionally with `kdp-listing`); actual uploads
are manual and belong to the user.

## Final report

End with: the output tree with file sizes and page counts, validation status
per artifact (epubcheck clean? preflight clean? KDP criticals?), and what
remains for the user (metadata gaps, uploads, pricing decisions).
