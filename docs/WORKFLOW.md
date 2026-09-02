# The aimprenta workflow

This file details the flagship pipeline — books. Three commands, thirteen
steps, five user gates. Validated end-to-end 2026-09-01 on "Collision Math
for Engineers" (idea → upload-ready in one session); the deterministic
gates, coherence read, and visual spot-check below were added after a
second real book (a Spanish ML textbook) surfaced the gaps they close — see
the design principles in the main [README](../README.md#using-it) for the
incidents that motivated each one.

The two lighter pipelines — [papers](#the-paper-workflow) and
[short-form articles](#the-article-workflow) — reuse the same skill layer
at a smaller scale and get their own, much shorter sections near the bottom
of this file, since neither needs a stage-by-stage breakdown this detailed.

```
IDEA
  │
  ▼ /book-author "idea or partial draft"
┌─────────────────────────────────────────────────────────────┐
│ Stage 1  Frame       brainstormer + research-analyst agents  │
│          → BRIEF.md                     ══ GATE: approve ══  │
│          (honest order-of-magnitude time/dispatch estimate   │
│           stated here, before any work begins)                │
│ Stage 2  Sources     lit-review (+paper-crawler)             │
│          → sources/references.bib + paper-cards.md           │
│          (every detail verified or marked TODO — never       │
│           guessed)                                           │
│ Stage 3  Outline     textbook-methodology +                  │
│          cross-reference-discipline → SYLLABUS.md            │
│          (Quarto-prefix labels planned here; sharper time/    │
│           dispatch estimate now that chapter count is known) │
│                                         ══ GATE: approve ══  │
│ Stage 4  Draft       writer/section-writer agents per        │
│          chapter; notebook-paired-with-prose: code/chNN/     │
│          modules generate every printed number, pytest pins  │
│          them, non-table prose claims tracked in             │
│          passport.yaml; then bookwright reviewer              │
│          (4 auditors) + rewriter fix-verify loop              │
│ Stage 5  De-AI       humanizer over all prose               │
│ Stage 6  Metadata    METADATA.md + the ISBN decision         │
│          (buy owned ISBNs BEFORE production, or record why   │
│           not — the copyright page gates interior builds)    │
└─────────────────────────────────────────────────────────────┘
  │  book/ + code/ + SYLLABUS.md + METADATA.md + passport.yaml
  ▼ /scientific-book-editor ./book/
┌─────────────────────────────────────────────────────────────┐
│ Phase 0  Deterministic gates — check_structure.py (truncation│
│          markers, empty sections, malformed fences) +        │
│          check_readability.py (Flesch outliers vs. book      │
│          average). Zero-cost, zero-ambiguity, run before any │
│          review budget is spent; findings fold into           │
│          editorial-report.md                                 │
│ Phase 1  Editorial panel — 7 parallel agents: the classic 5   │
│          (logic, technical, consistency, writing,             │
│          bibliography) plus an adversarial skeptic/advocate  │
│          pair (skeptic attacks the theses; advocate defends  │
│          deliberate authorial choices)                       │
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
│          sharded per chapter, verify-then-edit; re-verified  │
│          with check_claims.py (re-runs every chapter's       │
│          suite against passport.yaml, cross-referenced       │
│          against KNOWN-ISSUES.md so a documented              │
│          environment-version pin isn't mistaken for drift)   │
│ Phase 6  line-and-copy-editor → style-sheet.md                │
│ Phase 7  Whole-manuscript coherence read — ONE continuous     │
│          read of the entire revised-book/, never              │
│          chapter-sharded, hunting for defects only visible    │
│          accumulated across the whole book (repeated house    │
│          terminology, template fatigue, voice drift)          │
│          → coherence-report.md                                │
│          ══ GATE: approve which findings to fix ══           │
│          apply (chapter-sharded is fine here) → independent  │
│          grep sweep + check_claims.py re-run by the           │
│          orchestrator, not trusted from agent self-report     │
└─────────────────────────────────────────────────────────────┘
  │  revised-book/  (canonical source)
  ▼ /production-book-publisher ./revised-book/
┌─────────────────────────────────────────────────────────────┐
│ Step 8   book-typesetting — Quarto book project (crossrefs   │
│          resolve natively), 6×9 paperback + optional         │
│          hardcover trim → interior.pdf(s); STRIP annotations │
│          for KDP print; record page counts                   │
│ Step 9   kindle-book/pandoc path — EPUB3 with title/subtitle │
│          split; epubcheck to 0 errors                        │
│ Step 10  kindle-cover — wrap covers, spine from page count   │
│          (no spine text under ~130pp), fonts EMBEDDED,       │
│          typographic front if no cover asset; 1600×2560      │
│          cover.jpg; embed cover into the EPUB + re-check     │
│ Step 11  preflight (pdfinfo/pdffonts/annots/gs/inkcov),      │
│          check_claims.py re-verification, + kdp-audit        │
│          → validation/, PLUS a mandatory visual spot-check:  │
│          the orchestrator itself views rasterized front       │
│          matter, a math/figure/table page each, and 3+       │
│          pages spread through the book cross-checked          │
│          against expected chapter topics — automated checks  │
│          alone already passed a book with a chapter-          │
│          numbering offset bug once                            │
│          ══ GATE: Criticals (automated or visual) fixed or ══│
│          ══ accepted ══                                       │
│ Step 12  ebook-publishing (+kdp-listing) → distribution      │
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
- **Chapter-sharded review has a blind spot no amount of per-chapter rigor
  fixes**: a 14-chapter manuscript passed a 7-reviewer panel, independent peer
  review, a citation audit, and a 5-pass sciwrite review with zero
  chapter-sharded findings — then a cover-to-cover read found the same
  invented terminology repeated in 13 of 14 chapters. Phase 7 exists because
  no per-chapter reviewer's context window ever spans the whole book.
- **Automated checks don't see the rendered page**: `pdfinfo`, page counts,
  and `epubcheck` all passed a book with a chapter-numbering offset bug (a
  headingless front-matter file silently consumed chapter 1). Step 11's
  visual spot-check exists because that class of defect only shows up when
  someone actually looks at the pages.
- **Mechanical defects shouldn't cost review budget**: `check_structure.py`
  and `check_readability.py` catch truncation markers, empty sections, and
  readability outliers before Phase 1 spends a single LLM call — a confident
  chapter can talk a reviewer out of noticing these; it can't talk a script
  out of it.
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
   risky 20%). Still open — no book has needed a render path where this
   would help yet.

Adopted since this list was written: the `passport.yaml` per-claim
PASS/FAIL/STALE ledger (Stage 4, enforced by `check_claims.py`) and the
advocate/skeptic adversarial pair (Phase 1) are both now standard, not
recommendations.

## The paper workflow

`paper-author` + `paper-publisher`. Never shards — a paper fits in one
reviewer's context, so the Scale rule that drives the book pipeline's
per-chapter parallelism doesn't apply here. See
[`aimprenta-paper-pipeline.svg`](diagrams/aimprenta-paper-pipeline.svg) for
the diagram version of this graph.

```
RESEARCH QUESTION
  │
  ▼ /paper-author "a research question"
┌─────────────────────────────────────────────────────────────┐
│ Frame     research question, thesis, target venue → BRIEF.md │
│ Sources   lit-review — MANDATORY, never skipped for a paper  │
│ Draft     manuscript-drafting, single pass, no chapter-sharded│
│           agents; Introduction Arc / IMRaD structure          │
│                                         ══ GATE: approve ══  │
│           scope, sources, and venue                          │
│ Review    paper-review (single or panel) + citation-audit +  │
│           sciwrite, all three read the whole manuscript —    │
│           nothing to shard at this length                    │
│                                         ══ GATE: approve ══  │
│           application policy                                 │
│ Revise    manuscript-revision on the approved findings;       │
│           passport.yaml claims (if any) re-verified           │
└─────────────────────────────────────────────────────────────┘
  │  manuscript.md + references.bib
  ▼ /paper-publisher <paper-dir>
┌─────────────────────────────────────────────────────────────┐
│ Template  arXiv-style default (no fetch needed) or a named    │
│           venue's own class fetched live — never vendored,   │
│           see skills/paper-publisher/references/              │
│           venue-templates.md                                 │
│ Build     latexmk → paper.pdf; check_claims.py re-verification│
│           if the paper ships a passport.yaml                  │
│ Checklist page/word limit, anonymization if double-blind,     │
│           bibliography style, reproducibility statement       │
│                                         ══ GATE: Criticals ══│
│                                         ══ fixed or accepted ═│
└─────────────────────────────────────────────────────────────┘
  │
  ▼  submission/{paper.pdf, references.bib, validation/}
```

## The article workflow

`article-author` alone — one command, not three. A 600–2000 word piece
doesn't earn book-author's ceremony. See
[`aimprenta-article-pipeline.svg`](diagrams/aimprenta-article-pipeline.svg)
for the diagram version of this graph.

```
ANGLE
  │
  ▼ /article-author "an angle"
┌─────────────────────────────────────────────────────────────┐
│ Angle       thesis, audience, the one claim the piece exists │
│             to land                                           │
│ Fact-check  CONDITIONAL — only if the piece makes a           │
│             verifiable claim; skipped entirely for opinion    │
│             pieces, not a fixed phase                         │
│ Draft       single pass, one thesis, platform-appropriate     │
│             voice                                              │
│ Editorial   sciwrite (targeted, clarity/voice) + humanizer     │
│                                         ══ GATE: approve ══  │
│                                         to publish — the only │
│                                         gate in this pipeline │
│ Format      per platform (LinkedIn/Medium/plain markdown/     │
│             newsletter); limits/conventions checked live via  │
│             WebSearch, never hardcoded — they change          │
└─────────────────────────────────────────────────────────────┘
  │
  ▼  article.md + formatted/{platform}.md + platform-checklist.md
```
