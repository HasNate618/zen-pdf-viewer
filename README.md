# Zen PDF Viewer

A lightweight, local PDF.js-based viewer focused on a minimal, keyboard-first reading experience. It provides:

- Zen mode "dark reading" (grayscale → invert)
- Transparent/pageless rendering (compositors with blur/transparency may improve appearance)
- High-DPI canvas rendering for crisp output
- A selectable text layer (PDF.js text layer) so text can be copied/searched
- A small launcher script (zen-pdf-viewer) that serves PDFs from a temp directory and opens the viewer in your default browser (Zen Browser recommended for best transparency integration)

Table of contents
- Features
- Quick start
- How it works (architecture)
- Files & layout
- Usage & URL parameters
- Theming & customization
- Integration & desktop/browser setup
- Development & testing
- Contribution
- Troubleshooting
- Security & privacy


Features

- Pageless, transparent rendering; compositors with blur/transparency (e.g., Hyprland) can improve appearance
- Zen mode (optional) that greyscales and inverts page content while optionally preserving image colors
- High-resolution rendering using window.devicePixelRatio
- Selectable text via PDF.js text layer (renderTextLayer)
- Small launcher (zen-pdf-viewer) which downloads or copies a PDF into a temp dir, starts a local HTTP server bound to 127.0.0.1 and opens the viewer

Quick start

1. Ensure the repository is located at ~/Projects/zen-pdf-viewer and symlinked to ~/.local/share/pdfjs (this repository contains viewer.html and helper scripts):

   ln -sfn ~/Projects/zen-pdf-viewer ~/.local/share/pdfjs

2. Make sure the launcher is installed and executable at ~/.local/bin/zen-pdf-viewer (the project includes this script):

   chmod +x ~/.local/bin/zen-pdf-viewer

3. Open a PDF:

   zen-pdf-viewer /path/to/file.pdf

   The launcher will create a temporary dir, copy the PDF as doc.pdf, start a local HTTP server bound to 127.0.0.1 on a free port, and open the viewer URL via xdg-open so your default Zen browser profile handles it.


How it works (architecture)

- The viewer (viewer.html) uses PDF.js (loaded from a CDN by default) to parse and render PDF pages.
- Rendering pipeline (per page):
  1. PDF.js renders the page to a high-DPI canvas (respecting devicePixelRatio) for sharp output.
  2. The page's text is also rendered into an overlay text layer using PDF.js renderTextLayer so the text is selectable and searchable.
  3. If Zen mode is enabled, a post-process pass reads the canvas pixel data and applies a grayscale → invert transform (with a heuristic to preserve colorful image pixels when requested).
  4. For pageless transparent rendering, the viewer renders page backgrounds as transparent so the compositor shows through.

- The launcher (zen-pdf-viewer) handles local/remote PDFs by copying/downloading the file into a temp directory and serving it via python's http.server on 127.0.0.1. This avoids cross-origin restrictions and allows the viewer to load document data and worker scripts safely.

Files & layout

- viewer.html — The PDF.js-based viewer (main UI and rendering logic).
- zen-pdf-viewer — A small shell launcher script that prepares a temp dir, serves it, and opens the viewer URL in the default browser.
- README.md — This documentation.
- .git/ — (optional) repository for sharing and versioning.


Usage & URL parameters

The viewer accepts query parameters on the viewer.html URL. The launcher sets sane defaults, but you can call the viewer directly in a browser for testing:

- file: (required) file name on the same server (e.g. doc.pdf)
- fg: foreground color hex (e.g. %23dcfce7 for #dcfce7)
- bg: toolbar background (CSS color)
- zen: zen mode (1 = enabled, 0 = disabled)
- imgcolor: preserve image color when zen is enabled (1 = keep colors for images, 0 = recolor everything)

Example (launcher-generated):

http://127.0.0.1:PORT/viewer.html?file=doc.pdf&zen=1&imgcolor=0

Notes:
- The launcher sets zen=1 and imgcolor=0 by default (Zen mode enabled).
- If you disable zen (zen=0), the viewer renders pages normally.


Theming & customization

- Edit the `theme` constants at the top of viewer.html to modify colors and toolbar appearance (fg, toolbarBg, and CSS rules).
- By default PDF.js is loaded from a CDN. For offline or reproducible builds, vendor `pdf.min.js` and `pdf.worker.min.js` into the project and change GlobalWorkerOptions.workerSrc to a local path.
- Toolbar: compact, bottom-floating UI; change #toolbar CSS rules to reposition or resize.


Integration & desktop/browser setup

Make the viewer the default PDF handler (optional):

1. Create a desktop entry (example `~/.local/share/applications/zen-pdf-viewer.desktop`):

```
[Desktop Entry]
Name=Zen PDF Viewer
Exec=/home/youruser/.local/bin/zen-pdf-viewer %u
Terminal=false
Type=Application
MimeType=application/pdf
Categories=Utility;
```

2. Update the system default for PDFs:

   xdg-mime default zen-pdf-viewer.desktop application/pdf

3. For browsers that embed PDF viewers (Chrome/Chromium/Zen Browser), set the browser to open PDFs externally (so they open in the system default):

- For Chromium/Chrome-like browsers: set the profile pref `plugins.always_open_pdf_externally = true` (in profile prefs) or disable the built-in PDF viewer from the UI.
- For Zen Browser (optional), you may configure profile handlers to open PDFs externally; the launcher can assist but this is optional.


Development & testing

- Local dev: you can run a simple HTTP server in the project dir to test the viewer locally:

  cd ~/Projects/zen-pdf-viewer
  python3 -m http.server 8000 --bind 127.0.0.1

  Then open:
  http://127.0.0.1:8000/viewer.html?file=/path/to/some.pdf

- To vendor pdf.js instead of loading from CDN:
  1. Download `pdf.min.js` and `pdf.worker.min.js` for the PDF.js release you want.
  2. Place them in the project (e.g. `vendor/`) and update `viewer.html`:
     pdfjsLib.GlobalWorkerOptions.workerSrc = './vendor/pdf.worker.min.js';
     and change the script source to the local file.

- Performance:
  - The viewer now prioritizes rerendering around the current page first, so zoom/resize updates become visible sooner on large PDFs.
  - Rendering quality is adaptive for large documents (output scale is capped) to reduce CPU/GPU and memory pressure.
  - Very large PDFs can still be expensive, especially with Zen mode filtering enabled on high-resolution pages.


Contribution

- Fork and open a PR, include focused commits with descriptive messages.
- When creating commits locally using the helper scripts or Copilot, include the co-author trailer if applicable:

  Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

- If you add features that change the viewer API (query parameters or data layout), document them here.


Troubleshooting

- "Blank/black pages": Make sure Zen mode is pageless and uses transparent background; toggle Zen mode off to verify the original rendering.
- "Text not selectable": The text layer relies on PDF.js text extraction. Some PDFs are scanned images (no embedded text) — run OCR if you need selectable text.
- "Remote PDFs not rendering": The launcher downloads remote PDFs into a temp directory to avoid CORS restrictions. If testing directly, ensure the server supports range requests/CORS or use the launcher script.
- "Worker fails to load": If the worker is fetched from CDN, a network block or missing worker path will break rendering; vendor the worker to fix offline/packaged setups.


Security & privacy

- The launcher serves files only on 127.0.0.1 (localhost); no external network exposure is made by the server itself.
- By default the viewer pulls the pdf.js worker from a CDN. If you need full offline/privacy assurance, vendor the worker and pdf.js locally.
- The launcher copies PDFs into a temporary directory; the directory is left in /tmp until the server exits — if you need permanent cleanup add a wrapper to delete older temp dirs.


License

This repository does not include an explicit license file by default. Add a LICENSE file (e.g. MIT or permissive license) if you plan to share publicly.


Contact / Credits

- Author: your user account
- Built and iterated locally.


-- end --
