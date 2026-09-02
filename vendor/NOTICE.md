# Vendored third-party skills — notices

This directory contains verbatim copies of skill files from 9 upstream repositories,
each pinned to the exact commit recorded in `../vendors.lock`, vendored here so
`install.sh` works fully offline after `git clone` (no network calls to GitHub at
install time). All 9 carry a permissive license that allows redistribution with
attribution. The license text below is quoted from each repo's own `LICENSE` file
at the pinned commit; this NOTICE does not modify or supersede those licenses.

| Vendored as | Source | License | Pinned commit |
|---|---|---|---|
| `academic-writing-agents/` | github.com/andrehuang/academic-writing-agents | MIT | `d4d9d3a` |
| `research-skills/` | github.com/neuromechanist/research-skills | BSD-3-Clause | `af4f609` |
| `academic-human-in-the-loop/` | github.com/OpenGHz/academic-human-in-the-loop | MIT | `444bdae` |
| `manuscript-writing/` | github.com/YSLAB-ai/manuscript-writing | MIT | `f83e99f` |
| `claude-skills/` | github.com/ghanemzadeh/claude-skills | MIT | `3a8037d` |
| `book-typesetting-skill/` | github.com/yoelf22/book-typesetting-skill | MIT | `736461b` |
| `kindle-book-skill/` | github.com/nikmcfly/kindle-book-skill | MIT | `aa66cdf` |
| `claude-anvil/` | github.com/queelius/claude-anvil | MIT | `ed58e9a` |
| `ebook-publishing-skill/` | github.com/arturseo-geo/ebook-publishing-skill | MIT | `8c23481` |

## Deliberately NOT vendored here (stay as live `git clone` at install time)

| Skill | Source | Why not vendored |
|---|---|---|
| `sciwrite` | github.com/labarba/sciwrite | Custom license (not a recognized SPDX MIT/BSD/Apache term) — `install.sh` clones it live at the pinned SHA in `vendors.lock` instead of copying its source into this repo. |
| `kindle-cover` | github.com/nikmcfly/kindle-cover-skill | No `LICENSE` file in the upstream repo at all — no explicit grant to redistribute. Same live-clone treatment, plus the local `../patches/kindle-cover-trim-7x10.md` fix applied on top after cloning. |

If either upstream repo adds a clear permissive license later, move it into this
vendoring scheme and update this table.

## Optional, not part of `install.sh`

`scientific-manuscript-review` (used ad hoc during the *Fundamentos de Machine
Learning* production run, 2026-09-02) comes from a different installer
(`npx skills add`, the skills.sh marketplace) and its upstream source
(github.com/lyndonkl/claude) has no license file either. It is not wired into
`install.sh` for both reasons — installer mechanism mismatch and no
redistribution grant. See `docs/optional-skills.md` for how to add it manually.
