> **LOCAL PATCH (aimprenta install):** Upstream `generate_cover.py` only
> supports four trim sizes (`5x8`, `5.5x8.5`, `6x9`, `8.5x11`). Technical books
> with heavy code/figure density commonly use **7×10 in** (KDP-supported, not
> upstream-supported). This patch adds one entry to `TRIM_SIZES`:
>
> ```python
> "7x10":    {"w": 7.0,  "h": 10.0},
> ```
>
> Applied automatically by `install.sh` after cloning the vendor at its pinned
> SHA — additive only, does not touch the four existing trim sizes or any other
> behavior. First needed producing *Fundamentos de Machine Learning* (7×10,
> ~350pp with code+figures) on 2026-09-02.
