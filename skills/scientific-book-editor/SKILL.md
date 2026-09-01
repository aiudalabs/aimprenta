---
name: scientific-book-editor
description: >
  End-to-end editorial and scientific QA pipeline for book-length manuscripts
  (scientific, technical, nonfiction). Orchestrates six phases: global editorial
  assessment with a publishability verdict, scientific peer review, citation and
  evidence audit, scientific-writing improvement (sciwrite), manuscript revision,
  and a final line/copy edit. Use when the user says "/scientific-book-editor",
  "edit my book", "editorial pipeline", "review this book for publication",
  "run the editorial QA", or wants a publish / major-revision / don't-publish
  verdict on a full manuscript. Report-only until the user approves revisions.
  For production (PDF/EPUB/covers/KDP) use production-book-publisher instead.
argument-hint: "[book-source-dir]"
---

# Scientific Book Editor — Editorial QA Orchestrator

Orchestrates the editorial half (steps 1–6) of the book pipeline. Input: a
directory of markdown chapter files (optionally BibTeX / a references section).
Output: four review reports, a publishability verdict, and — only after user
approval — a revised copy of the book.

**Never edit the input manuscript in place.** Reviews are report-only; revision
happens on a copy. Never fabricate citations, data, or numbers anywhere in the
pipeline.

## Inputs and outputs

- Input: `<book-dir>` — chapter markdown files (`ch*.md` or similar). If the
  argument is missing, ask for it; do not guess.
- Reports go to `<book-dir>/../editorial/` (or `./editorial/` next to the book):
  `editorial-report.md`, `scientific-review.md`, `citation-audit.md`,
  `writing-review.md`, `style-sheet.md`.
- Revised manuscript goes to `<book-dir>/../revised-book/` (a full copy, then
  edited).

## Scale rule (books are not papers)

Every phase below was designed for papers; a book is 10–20× longer. For any
manuscript over ~15k words, shard by chapter: spawn parallel subagents (2
chapters each is a good grain), have each write its full report to a file
(message transit truncates long reports), then compile one combined report
with an executive summary, severity totals (CRITICAL/MAJOR/MINOR), and
cross-book patterns. This mirrors how each underlying skill is applied.

## Phase 1 — Global editorial assessment → `editorial-report.md`

Uses the academic-writing-agents reviewer roster (installed in
`~/.claude/agents/`): spawn in parallel, each over the whole manuscript or
chapter shards:

- `logic-reviewer` — argument structure, non-sequiturs, unsupported leaps
- `technical-reviewer` — technical correctness of claims and examples
- `consistency-checker` — terminology, notation, cross-references
- `writing-reviewer` — prose quality at the structural level
- `bibliography-auditor` — reference list hygiene (existence checked in Phase 3)

Synthesize into `editorial-report.md` ending with a **verdict**, exactly one of:
`PUBLISH` · `MINOR REVISION` · `MAJOR REVISION` · `DO NOT PUBLISH`, each with
the blocking findings that justify it.

**Gate:** on `DO NOT PUBLISH`, stop the pipeline and report to the user. On any
other verdict, continue.

## Phase 2 — Scientific peer review → `scientific-review.md`

Invoke the `paper-review` skill (Panel mode). For a book, run the panel per
module or chapter-pair: methodology soundness, statistical/numerical validity,
reproducibility of any executable claims, unsupported assertions. If the book
ships executable code that generates its tables/figures, RUN it and compare
against the printed values — never assume.

## Phase 3 — Citation & evidence audit → `citation-audit.md`

Invoke the `citation-audit` skill (note its LOCAL ADAPTATION header: reviewer
calls use fresh Claude subagents, not Codex). For every reference: does it
exist, is the bibliographic data correct, and does the cited source actually
support the claim at the citation site (the telephone-game check). Verify via
WebSearch/WebFetch against primary sources. Flag secondary-source-only
statistics.

## Phase 4 — Scientific writing improvement → `writing-review.md`

Invoke the `sciwrite` skill in full-review mode (five passes: clutter, voice,
sentence architecture, terminology consistency, numerical/citation
consistency), sharded per the scale rule. Recompute every table from its stated
assumptions in Pass 5.

## Phase 5 — Manuscript revision → `revised-book/` (GATED)

**Gate: present the consolidated findings to the user first** — totals by
severity, the CRITICAL list in full, and the recommended application policy
(default: apply CRITICAL + MAJOR + mechanical MINORs; skip taste-level items
like verbal tics, voice policy, spelling register — those are author
decisions). Wait for approval.

Then copy the book to `revised-book/` and invoke `manuscript-revision` in
revision mode to apply the approved changes there, sharded by chapter. Rules
for appliers: locate edits by the report's exact ORIGINAL text; where a finding
contradicts program output, run the program first and fix the wrong side; where
a claim quotes shipped code verbatim, never silently change either side. After
edits, re-run the book's own test suites / build if it has them.

## Phase 6 — Final line/copy edit → `style-sheet.md`

Invoke `line-and-copy-editor` on `revised-book/`: grammar, consistency,
Chicago-style cleanup, AI-artifact removal. It maintains a running style sheet
— save it as `editorial/style-sheet.md`. This is the last pass before the
manuscript becomes the canonical source for `production-book-publisher`.

## Failure and honesty rules

- A phase that cannot run (missing tool, missing input) is reported as skipped
  with the reason — never silently dropped, never simulated.
- Findings must quote ORIGINAL text and give a concrete revision. No "consider
  improving clarity".
- Verdicts and severity counts in the final summary must match the report files
  exactly.
