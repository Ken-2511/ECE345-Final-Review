# Pandoc + Eisvogel Workflow

This folder packages everything needed to turn the repository notes into a clean, A4-ready PDF using Pandoc and the Eisvogel LaTeX template.

## Source of Truth
- `review-notes.md` mirrors the main `README.md` content and already contains the metadata required by Eisvogel (title, headers, footer, etc.).
- Edit `review-notes.md` (not the root README) whenever you want the printable PDF to change, then regenerate the document.

## Prerequisites
1. **Pandoc** (2.9 or newer) — https://pandoc.org/installing.html
2. **LaTeX distribution** with `xelatex` (TeX Live, MiKTeX, or MacTeX). Ensure the `minted` and `pgfplots` packages are installed (Eisvogel uses them when `listings: true`).
3. **PowerShell 5+** (already available on Windows 10/11) if you plan to run the helper script.

## Template Setup
- The helper script downloads `eisvogel.tex` automatically to `print/templates/eisvogel.tex` on first run.
- To download manually:
  ```powershell
  New-Item -ItemType Directory -Force -Path print\templates | Out-Null
  Invoke-WebRequest `
    -Uri https://raw.githubusercontent.com/Wandmalfarbe/pandoc-latex-template/master/eisvogel.tex `
    -OutFile print\templates\eisvogel.tex
  ```

## One-Line Pandoc Command
Run the following from the repository root once the template exists:
```powershell
pandoc print/review-notes.md `
  -o dist/ECE345-Final-Review.pdf `
  --from markdown `
  --template print/templates/eisvogel.tex `
  --pdf-engine xelatex `
  --listings
```
Notes:
- `dist/` will be created automatically by the helper script; make sure the folder exists when running Pandoc manually.
- Add `--toc` or extra metadata flags if you temporarily need to override the YAML header.

## PowerShell Helper Script
- `build-pdf.ps1` wraps the command above, guarantees folders exist, downloads the template if missing, and writes to `dist/ECE345-Final-Review.pdf` by default.
- Example usage from the repo root:
  ```powershell
  .\print\build-pdf.ps1
  ```
- Optional parameters:
  - `-Output "C:\\temp\\ece345.pdf"` to choose another destination.
  - `-TemplatePath "D:\\tex\\eisvogel.tex"` if you keep a shared template elsewhere.

With Pandoc + Eisvogel configured, the resulting PDF is typeset by LaTeX, yielding a publication-quality handout that prints neatly on A4 paper.
