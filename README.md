# Zen PDF viewer (Omarchy theme)

A lightweight, local PDF.js-based viewer tailored for Omarchy (Hyprland) users. It provides:

- Zathura-style "dark reading" mode (grayscale → invert) that mimics zathura's appearance
- Transparent/pageless rendering so the compositor's blur/desktop background shows through
- High-DPI canvas rendering for crisp output
- A selectable text layer (PDF.js text layer) so text can be copied/searched
- A tiny launcher script (zen-pdf-viewer) that serves PDFs from a temp directory and opens the viewer in your default Zen browser profile

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

- Pageless, transparent view that takes advantage of Hyprland/Omarchy compositor blur and transparency
- Zathura-like reading mode (optional) that greyscales and inverts page content while preserving image colors optionally
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
  3. If Zathura mode is enabled, a post-process pass reads the canvas pixel data and applies a grayscale → invert transform (with a heuristic to preserve colorful image pixels when requested).
  4. For pageless transparent rendering, the viewer renders page backgrounds as transparent so the compositor shows through.

- The launcher (zen-pdf-viewer) handles local/remote PDFs by copying/downloading the file into a temp directory and serving it via python's http.server on 127.0.0.1. This avoids cross-origin restrictions and allows the viewer to load document data and worker scripts safely.

Files & layout

- viewer.html — The PDF.js based Omarchy viewer (main UI and rendering logic).
- zen-pdf-viewer — A small shell launcher script that prepares a temp dir, serves it, and opens the viewer URL in the default browser.
- README.md — This documentation.
- .git/ — (optional) repository for sharing and versioning.


Usage & URL parameters

The viewer accepts query parameters on the viewer.html URL. The launcher sets sane defaults, but you can call the viewer directly in a browser for testing:

- file: (required) file name on the same server (e.g. doc.pdf)
- fg: foreground color hex (e.g. %23dcfce7 for #dcfce7)
- bg: toolbar background (CSS color)
- zmode: zathura mode (1 = enabled, 0 = disabled)
- imgcolor: preserve image color when zmode is enabled (1 = keep colors for images, 0 = recolor everything)

Example (launcher-generated):

http://127.0.0.1:PORT/viewer.html?file=doc.pdf&fg=%23dcfce7&bg=rgba(18,17,17,0.45)&zmode=1&imgcolor=0

Notes:
- The launcher sets zmode=1 and imgcolor=0 by default so the viewer opens in Omarchy zathura-like mode.
- If you disable zmode (zmode=0), the viewer renders pages normally.


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
- For Zen Browser specifically, ensure the profile's handlers.json or prefs instructs opening PDFs externally (the launcher edits these when requested).


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
  - The viewer uses devicePixelRatio to render crisp pages. For very large pages or files, memory usage may be high.
  - Consider reducing default scale or enabling streaming in PDF.js options for very large documents.


Contribution

- Fork and open a PR, include focused commits with descriptive messages.
- When creating commits locally using the helper scripts or Copilot, include the co-author trailer if applicable:

  Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

- If you add features that change the viewer API (query parameters or data layout), document them here.


Troubleshooting

- "Blank/black pages": Make sure Zathura mode is pageless and uses transparent background; toggle Zathura mode off to verify the original rendering.
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
- Built/iterated using Omarchy skill helper and helper scripts.


-- end --
