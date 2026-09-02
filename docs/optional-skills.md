# Optional skills — not installed by `install.sh`

These extend the pipeline but aren't wired into the automated install, either
because their installer mechanism doesn't match `vendors.lock` (git clone at a
pinned SHA) or their upstream license is unclear. Install manually if you want
them.

## scientific-manuscript-review

Used ad hoc during the *Fundamentos de Machine Learning* production run
(2026-09-02) as an emergency deep-read audit after the standard editorial
pipeline (Phase 1–6 of `scientific-book-editor`) had already passed the
manuscript — it caught a book-wide voice/terminology problem none of the
per-chapter or per-dimension reviewers surfaced, because it was the only pass
that read chapters end-to-end the way a human reader does.

Installer: [skills.sh](https://skills.sh) marketplace (`npx skills add`), not
a plain git clone — a different mechanism from every other dependency in this
repo. Source: [github.com/lyndonkl/claude](https://github.com/lyndonkl/claude)
— no `LICENSE` file at the time of writing, so (like `sciwrite` and
`kindle-cover`) it is not vendored here; install it live instead:

```bash
npx skills add https://github.com/lyndonkl/claude --skill scientific-manuscript-review
```

Suggested use: after `scientific-book-editor` finishes and before
`production-book-publisher` runs, spot-read 2–3 chapters yourself first. If
you suspect a whole-book voice/repetition problem invisible to per-chapter
review (the exact failure mode this caught), invoke this skill over the full
`revised-book/` directory.

## Diagram tools (see `docs/diagrams.md`)

`archify` and `diagram-design` are Claude Code / Codex / Cursor skills and
plugins, not aimprenta dependencies — they don't touch the manuscript
pipeline at all, only how process diagrams (this repo's own docs) and in-book
conceptual figures get drawn. Kept separate from `vendors.lock` on purpose:
neither produces book *content*, so neither belongs in the reproducibility
chain that `passport.yaml` and the test suites protect.
