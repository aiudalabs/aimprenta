#!/usr/bin/env bash
# book-pipeline doctor — verify the external toolchain. Exit 1 if a REQUIRED tool is missing.
ok=0; miss=0
req() { if command -v "$1" >/dev/null 2>&1; then printf '  \033[32mok\033[0m   %-12s %s\n' "$1" "$(command -v "$1")"; ok=$((ok+1)); else printf '  \033[31mMISS\033[0m %-12s %s\n' "$1" "$2"; miss=$((miss+1)); fi; }
opt() { if command -v "$1" >/dev/null 2>&1; then printf '  \033[32mok\033[0m   %-12s %s\n' "$1" "$(command -v "$1")"; else printf '  \033[33mwarn\033[0m %-12s %s\n' "$1" "$2"; fi; }

echo "== REQUIRED (editorial + production core) =="
req git      "install via Xcode CLT or brew"
req python3  "brew install python"
req pandoc   "brew install pandoc"
req gs       "brew install ghostscript"
req quarto   "https://quarto.org/docs/get-started/ (installer, not brew)"
req xelatex  "MacTeX (https://tug.org/mactex/) or TeX Live — large installer"
req epubcheck "brew install epubcheck"

echo "== OPTIONAL (quality of life) =="
opt magick     "brew install imagemagick — image prep"
opt pdftoppm   "brew install poppler — page rasterization for visual QC"
opt pdfinfo    "brew install poppler"
opt uv         "https://docs.astral.sh/uv/ — faster venv management"
opt node       "brew install node — some vendor tooling"

echo "== LaTeX packages the print layout uses =="
if command -v kpsewhich >/dev/null 2>&1; then
  missing=""
  for p in imakeidx.sty xurl.sty fvextra.sty; do kpsewhich "$p" >/dev/null 2>&1 || missing="$missing ${p%.sty}"; done
  if [ -n "$missing" ]; then printf '  \033[33mwarn\033[0m packages missing:%s — tlmgr install%s (may need sudo)\n' "$missing" "$missing"; else echo "  ok   imakeidx xurl fvextra present"; fi
else
  printf '  \033[33mwarn\033[0m kpsewhich not found — TeX Live not on PATH\n'
fi

echo
if [ "$miss" -gt 0 ]; then echo "$miss required tool(s) missing."; exit 1; else echo "All required tools present."; fi
