---
name: book-author
description: >
  Phase 0 of the book pipeline: take a book from idea to a review-ready
  manuscript. Orchestrates ideation, literature gathering, outline design,
  chapter drafting (with optional executable-chapter methodology), AI-tell
  removal, cross-reference discipline, and the metadata/ISBN checklist. Use
  when the user says "/book-author", "start a new book", "draft my book",
  "write a book about X", or "new book project". Hands off to
  scientific-book-editor (editorial QA) and then production-book-publisher
  (formats/publishing). Do NOT use for reviewing or producing an existing
  manuscript — those are the other two orchestrators.
argument-hint: "[book-dir-or-idea]"
---

# Book Author — Phase 0 Orchestrator

Takes an idea (or a partial draft) to a manuscript ready for
`/scientific-book-editor`. Output: `<book-dir>/book/` chapter markdown +
`METADATA.md` + (optional) `code/` per-chapter modules + a syllabus/outline
file that later phases treat as canonical.

**Honesty rules apply from the first word:** no invented citations, data,
statistics, or numbers anywhere. A claim without a source is flagged
`[source needed]`, never dressed up. Real facts come from lit-review /
WebSearch, or from code the chapter actually runs.

## Stage 1 — Frame the book

Interview the user briefly (subject, audience, what the reader can do after
reading, scope boundaries), then spawn `brainstormer` and `research-analyst`
agents to pressure-test the concept: what exists already, what's the gap, what
would make this book distinctive. Produce `BRIEF.md` (one page). **Gate: user
approves the brief.**

## Stage 2 — Sources

For a book making factual/technical claims, invoke `lit-review` (multi-phase,
citation-traceable; `paper-crawler` agent for DBLP/OpenAlex sweeps when the
domain is academic). Output: `sources/` with paper cards + a BibTeX or
reference list the later citation-audit can verify. Books that are pure
practitioner experience may skip with a note in BRIEF.md.

## Stage 3 — Outline

Invoke `textbook-methodology` (bookwright): atom-outward design, deferral
discipline, running threads, page budgets. Output: `SYLLABUS.md` mapping
modules → chapters → sections, with per-chapter page budgets and dependency
order. This file is canonical downstream — later phases (module references,
build order) read it, so keep it updated when scope changes. **Gate: user
approves the outline.**

## Stage 4 — Draft chapters

Per chapter (parallel agents, but respect the syllabus dependency order for
running threads):

- Prose: `manuscript-drafting` conventions + the `writer`/`section-writer`
  agents, following `cross-reference-discipline` for labels and forward
  references from the first draft (retrofitting cross-refs is the expensive
  path).
- **Executable chapters (strongly recommended for technical books):** invoke
  `notebook-paired-with-prose` — every table/figure in the prose is produced
  by a runnable module in `code/chNN/`, with a test suite pinning the printed
  numbers. This is what makes the later review phases verify instead of
  trust. Fresh-kernel execution before a chapter is called done.
- After each module of chapters: `iterator` + `quality-auditor` +
  `math-auditor` agents for a self-review pass before moving on (cheaper than
  finding structural problems at Phase 1).

## Stage 5 — De-AI pass

Invoke `humanizer` over every chapter: AI vocabulary, em-dash and
rule-of-three overuse, uniform paragraph rhythm. Run BEFORE Phase 1 —
line-and-copy-editor at the end of Phase 1 also hunts AI artifacts, and two
independent passes catch more than one.

## Stage 6 — Metadata and the ISBN gate

Write `METADATA.md`: title, subtitle, author (legal name as it should appear),
description (back-cover length), language, category intentions. Then tell the
user plainly: **buy ISBNs now** (owned ISBNs, one per format — see the
distribution checklist rationale) so the copyright page is correct before
Phase 2 builds interiors. Record the decision either way.

## Handoff

Final report: chapter word counts, executable-chapter coverage, source count,
open `[source needed]` flags, and the exact next command:
`/scientific-book-editor <book-dir>/book/`.
