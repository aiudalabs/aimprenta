# Optional skills — not installed by `install.sh`

These extend the pipeline but aren't wired into the automated install, either
because their installer mechanism doesn't match `vendors.lock` (git clone at a
pinned SHA) or their upstream license is unclear. Install manually if you want
them.

## scientific-manuscript-review

Originally used ad hoc during the *Fundamentos de Machine Learning*
production run (2026-09-02) as an emergency deep-read audit after the
standard editorial pipeline had already passed the manuscript — it caught a
book-wide voice/terminology problem none of the per-chapter or
per-dimension reviewers surfaced, because it was the only pass that read
chapters end-to-end the way a human reader does.

That specific gap is now covered natively: `scientific-book-editor`'s
**Phase 7** is a mandatory, gated whole-manuscript coherence read built
directly into the pipeline (see `skills/scientific-book-editor/SKILL.md`),
so this skill is no longer the primary mitigation for a book-wide
voice/repetition problem. What it's still useful for is a *second*,
differently-structured whole-book read — its IMRaD-oriented, per-section
(gap statement / results paragraph / discussion arc) checklist catches
things a coherence-focused pass isn't looking for, particularly on books
closer to a research-paper register than a textbook one. Reach for it as a
supplementary deep read, not a required step.

Installer: [skills.sh](https://skills.sh) marketplace (`npx skills add`), not
a plain git clone — a different mechanism from every other dependency in this
repo. Source: [github.com/lyndonkl/claude](https://github.com/lyndonkl/claude)
— no `LICENSE` file at the time of writing, so (like `sciwrite` and
`kindle-cover`) it is not vendored here; install it live instead:

```bash
npx skills add https://github.com/lyndonkl/claude --skill scientific-manuscript-review
```

Suggested use: after `scientific-book-editor`'s Phase 7 has already run and
been applied, and before `production-book-publisher` runs, invoke this
skill over `revised-book/` if you want a second opinion in a different
review frame — not as a substitute for Phase 7.

## Diagram tools (see `docs/diagrams.md`)

`archify` and `diagram-design` are Claude Code / Codex / Cursor skills and
plugins, not aimprenta dependencies — they don't touch the manuscript
pipeline at all, only how process diagrams (this repo's own docs) and in-book
conceptual figures get drawn. Kept separate from `vendors.lock` on purpose:
neither produces book *content*, so neither belongs in the reproducibility
chain that `passport.yaml` and the test suites protect.
