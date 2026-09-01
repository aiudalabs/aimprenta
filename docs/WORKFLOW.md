# The book-pipeline workflow

Three commands, eleven steps, four user gates. Validated end-to-end 2026-09-01
on "Collision Math for Engineers" (idea → upload-ready in one session).

```
IDEA
  │
  ▼ /book-author "idea or partial draft"
┌─────────────────────────────────────────────────────────────┐
│ Stage 1  Frame       brainstormer + research-analyst agents  │
│          → BRIEF.md                     ══ GATE: approve ══  │
│ Stage 2  Sources     lit-review (+paper-crawler)             │
│          → sources/references.bib + paper-cards.md           │
│          (every detail verified or marked TODO — never       │
│           guessed)                                           │
│ Stage 3  Outline     textbook-methodology +                  │
│          cross-reference-discipline → SYLLABUS.md            │
│          (Quarto-prefix labels planned here)                 │
│                                         ══ GATE: approve ══  │
│ Stage 4  Draft       writer/section-writer agents per        │
│          chapter; notebook-paired-with-prose: code/chNN/     │
│          modules generate every printed number, pytest pins  │
│          them; then bookwright reviewer (4 auditors) +       │
│          rewriter fix-verify loop                            │
│ Stage 5  De-AI       humanizer over all prose               │
│ Stage 6  Metadata    METADATA.md + the ISBN decision         │
│          (buy owned ISBNs BEFORE production, or record why   │
│           not — the copyright page gates interior builds)    │
└─────────────────────────────────────────────────────────────┘
  │  book/ + code/ + SYLLABUS.md + METADATA.md
  ▼ /scientific-book-editor ./book/
┌─────────────────────────────────────────────────────────────┐
│ Phase 1  Editorial panel — 5 parallel agents (logic,         │
│          technical, consistency, writing, bibliography)      │
│          → editorial/editorial-report.md                     │
│          ══ VERDICT: PUBLISH/MINOR/MAJOR/DON'T ══            │
│          (DON'T PUBLISH stops the pipeline)                  │
│ Phase 2  paper-review — independent fresh-context peer       │
│          review; RUNS the code → scientific-review.md        │
│ Phase 3  citation-audit — existence + telephone-game check   │
│          against primary sources → citation-audit.md         │
│ Phase 4  sciwrite — 5-pass writing audit → writing-review.md │
│          ══ GATE: approve application policy ══              │
│ Phase 5  manuscript-revision on a COPY (revised-book/),      │
│          sharded per chapter, verify-then-edit, suites +     │
│          table byte-match re-verified                        │
│ Phase 6  line-and-copy-editor → style-sheet.md               │
└─────────────────────────────────────────────────────────────┘
  │  revised-book/  (canonical source)
  ▼ /production-book-publisher ./revised-book/
┌─────────────────────────────────────────────────────────────┐
│ Step 7   book-typesetting — Quarto book project (crossrefs   │
│          resolve natively), 6×9 paperback + optional         │
│          hardcover trim → interior.pdf(s); STRIP annotations │
│          for KDP print; record page counts                   │
│ Step 8   kindle-book/pandoc path — EPUB3 with title/subtitle │
│          split; epubcheck to 0 errors                        │
│ Step 9   kindle-cover — wrap covers, spine from page count   │
│          (no spine text under ~130pp), fonts EMBEDDED,       │
│          typographic front if no cover asset; 1600×2560      │
│          cover.jpg; embed cover into the EPUB + re-check     │
│ Step 10  preflight (pdfinfo/pdffonts/annots/gs/inkcov) +     │
│          kdp-audit → validation/                             │
│          ══ GATE: Criticals fixed or accepted ══             │
│ Step 11  ebook-publishing (+kdp-listing) → distribution      │
│          checklist; uploads stay manual                      │
└─────────────────────────────────────────────────────────────┘
  │
  ▼  dist/{ebook/book.epub+cover.jpg, paperback/interior.pdf+cover.pdf,
           [hardcover/], validation/}
```

## Hard-won lessons already encoded

- Agent reports > message transit: long reviews get written to files
  (messages truncate); read-only reviewer agents resend in parts.
- Chapter-sharded parallel agents with STRICT file ownership; a coordination
  sweep by the orchestrator afterward for the items agents defer to each other.
- KDP print rejects annotations — strip them post-build (pypdf), don't wait
  for the audit loop.
- ReportLab leaks unembedded base-14 Helvetica into cover resources — set
  `initialFontName` to an embedded face.
- EPUBs need the cover embedded (`properties="cover-image"` + spine-first
  cover.xhtml + mimetype-first rezip), not just a JPEG on disk.
- pytest caches lie; count tests from source or a fresh run.
- METADATA.md is the single source for title/author/ISBN state; production
  never invents a value.

## Recommended next upgrades (community-validated, see community-validation.md)

1. Layer Paged.js into any HTML→Chromium render path (pagination CSS is the
   risky 20%).
2. Adopt a passport.yaml-style per-claim PASS/FAIL/STALE ledger to extend
   number-pinning into prose claims.
3. Add an advocate/skeptic adversarial pair to the Phase 1 panel.
