# Zen PDF Viewer

<p align="center">
  <img src="Media/screenshot.png" alt="Zen mode screenshot" width="500" />
</p>

**Zen mode — comfortable dark reading with transparent, pageless rendering.**

A lightweight, keyboard-first PDF viewer built on PDF.js. It runs entirely in your browser via a tiny local HTTP server — no Electron, no native app, no install wizard. One HTML file plus a launcher script is all it takes.

- **Zen mode** — grayscale + invert for comfortable dark reading, with optional image-color preservation
- **Pageless transparent rendering** — compositor blur/transparency (e.g. Hyprland) shows through the page background
- **SVG-first rendering** — vector-sharp pages at browser/pinch zoom (including pageless/Zen), with canvas fallback when forced or unsupported
- **Selectable text** — PDF.js text layer lets you copy and search text in any PDF
- **Keyboard-first** — vim-style navigation, dual-page mode, zoom, rotation, jump list, and more
- **Cross-platform** — Linux, macOS, and Windows via the included launcher scripts

---

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
  - [Nix](#nix)
  - [Linux](#linux)
  - [macOS](#macos)
  - [Windows](#windows)
- [Set as Default PDF Viewer](#set-as-default-pdf-viewer)
  - [Linux](#linux-1)
  - [macOS](#macos-1)
  - [Windows](#windows-1)
- [Usage](#usage)
- [Keyboard Shortcuts](#keyboard-shortcuts)
- [URL Parameters](#url-parameters)
- [Theming & Customization](#theming--customization)
- [How It Works](#how-it-works)
- [Troubleshooting](#troubleshooting)
- [Security & Privacy](#security--privacy)
- [Contributing](#contributing)

---

## Requirements

| Dependency | Notes |
|---|---|
| **Python 3** | Ships with macOS 12+; install from python.org on Windows; `python3` on Linux |
| **Modern browser** | Chrome, Firefox, Safari, Zen Browser, Edge — anything that supports PDF.js |
| **curl** (Linux/macOS) | Used by the launcher to download remote PDFs; wget works too |
| **Internet** (optional) | PDF.js is bundled in `vendor/`; no network needed to open local PDFs |

---

## Installation

### Nix

Install from the flake (requires [flakes](https://nix.dev/concepts/flakes.html) enabled):

```bash
nix profile install github:HasNate618/zen-pdf-viewer
```

Or build and run from a local checkout:

```bash
git clone https://github.com/HasNate618/zen-pdf-viewer.git
cd zen-pdf-viewer
nix run . -- /path/to/document.pdf
```

For a one-off install into your profile:

```bash
nix profile install .
```

The package installs `zen-pdf-viewer` on your `PATH` with `viewer.html` and `zen-server.py` bundled in the Nix store. Python 3, curl, and `xdg-open` (Linux) are wrapped automatically.

**NixOS / home-manager** — add the flake as an input and reference `packages.${pkgs.system}.default`, or use an overlay:

```nix
# flake.nix inputs
zen-pdf-viewer.url = "github:HasNate618/zen-pdf-viewer";

# configuration
environment.systemPackages = [ inputs.zen-pdf-viewer.packages.${pkgs.system}.default ];
```

**Dev shell** — for hacking on `viewer.html` without installing:

```bash
nix develop
python3 -m http.server 8000 --bind 127.0.0.1
```

---

### Linux

1. **Clone the repository:**

   ```bash
   git clone https://github.com/HasNate618/zen-pdf-viewer.git ~/Projects/zen-pdf-viewer
   ```

2. **Copy `viewer.html`, `zen-server.py`, and `vendor/` to the viewer data directory:**

   ```bash
   mkdir -p ~/.local/share/zen-pdf-viewer
   cp ~/Projects/zen-pdf-viewer/viewer.html ~/Projects/zen-pdf-viewer/zen-server.py ~/.local/share/zen-pdf-viewer/
   cp -r ~/Projects/zen-pdf-viewer/vendor ~/.local/share/zen-pdf-viewer/
   ```

   > **Migrating from an older install?** If you previously used `~/.local/share/pdfjs`, either copy `viewer.html` there too or update your existing launcher script to point at `~/.local/share/zen-pdf-viewer`.

3. **Install the launcher:**

   ```bash
   cp ~/Projects/zen-pdf-viewer/launch.sh ~/.local/bin/zen-pdf-viewer
   chmod +x ~/.local/bin/zen-pdf-viewer
   ```

   Make sure `~/.local/bin` is on your `PATH` (add `export PATH="$HOME/.local/bin:$PATH"` to your shell profile if needed).

4. **Test it:**

   ```bash
   zen-pdf-viewer /path/to/some.pdf
   ```

---

### macOS

1. **Clone the repository:**

   ```bash
   git clone https://github.com/HasNate618/zen-pdf-viewer.git ~/Projects/zen-pdf-viewer
   ```

2. **Copy `viewer.html`, `zen-server.py`, and `vendor/` to the viewer data directory:**

   ```bash
   mkdir -p "$HOME/Library/Application Support/zen-pdf-viewer"
   cp ~/Projects/zen-pdf-viewer/viewer.html ~/Projects/zen-pdf-viewer/zen-server.py "$HOME/Library/Application Support/zen-pdf-viewer/"
   cp -r ~/Projects/zen-pdf-viewer/vendor "$HOME/Library/Application Support/zen-pdf-viewer/"
   ```

3. **Install the launcher:**

   ```bash
   cp ~/Projects/zen-pdf-viewer/launch.sh /usr/local/bin/zen-pdf-viewer
   chmod +x /usr/local/bin/zen-pdf-viewer
   ```

   If you use Homebrew and prefer `~/.local/bin`, that works too — just make sure the directory is on your `PATH`.

4. **Verify Python 3 is available:**

   ```bash
   python3 --version
   ```

   If not installed, get it from [python.org](https://www.python.org/downloads/) or `brew install python`.

5. **Test it:**

   ```bash
   zen-pdf-viewer /path/to/some.pdf
   ```

---

### Windows

1. **Clone or download the repository** to a permanent location, e.g. `C:\Tools\zen-pdf-viewer`.

   ```powershell
   git clone https://github.com/HasNate618/zen-pdf-viewer.git C:\Tools\zen-pdf-viewer
   ```

2. **Copy `viewer.html`, `zen-server.py`, and `vendor/` to the viewer data directory:**

   ```powershell
   $dest = "$env:APPDATA\zen-pdf-viewer"
   New-Item -ItemType Directory -Force $dest
   Copy-Item C:\Tools\zen-pdf-viewer\viewer.html, C:\Tools\zen-pdf-viewer\zen-server.py $dest
   Copy-Item C:\Tools\zen-pdf-viewer\vendor $dest -Recurse
   ```

3. **Verify Python 3 is available:**

   ```powershell
   python --version
   ```

   If not installed, get it from [python.org](https://www.python.org/downloads/). Make sure the installer adds Python to `PATH`.

4. **Test it from PowerShell:**

   ```powershell
   & C:\Tools\zen-pdf-viewer\launch.ps1 C:\path\to\some.pdf
   ```

   Or use the batch wrapper (useful for file associations):

   ```cmd
   C:\Tools\zen-pdf-viewer\launch.bat C:\path\to\some.pdf
   ```

---

## Set as Default PDF Viewer

### Linux

1. **Create a desktop entry** at `~/.local/share/applications/zen-pdf-viewer.desktop`:

   ```ini
   [Desktop Entry]
   Name=Zen PDF Viewer
   Exec=/home/YOUR_USERNAME/.local/bin/zen-pdf-viewer %u
   Terminal=false
   Type=Application
   MimeType=application/pdf;
   Categories=Utility;
   ```

   Replace `YOUR_USERNAME` with your actual username (or use `$HOME` — some systems expand it, some do not; the absolute path is safest).

2. **Register it as the default:**

   ```bash
   xdg-mime default zen-pdf-viewer.desktop application/pdf
   update-desktop-database ~/.local/share/applications
   ```

3. **Make browsers open PDFs externally** (optional):
   - **Chromium / Chrome**: Settings → Privacy and security → Site settings → Additional content settings → PDF documents → **Download PDFs**
   - **Firefox**: Settings → General → Files and Applications → Portable Document Format (PDF) → **Save File** (then your system default handles it)

---

### macOS

The easiest method is to create a minimal Automator app that wraps the launcher, then assign it as the system default.

1. **Open Automator** (Spotlight → "Automator"), choose **New Document → Application**.

2. In the search bar type "Run Shell Script", drag it into the workflow.

3. Set **Pass input** to `as arguments` and paste:

   ```bash
   /usr/local/bin/zen-pdf-viewer "$@"
   ```

4. **Save** as `Zen PDF Viewer.app` inside `/Applications`.

5. **Set as default:**
   - Right-click any `.pdf` file in Finder → **Get Info**
   - Under **Open with**, select `Zen PDF Viewer.app`
   - Click **Change All…** → Continue

From then on, double-clicking any PDF will launch the viewer.

> **Alternative (command line):** If you have the `duti` tool (`brew install duti`), run:
> ```bash
> # First find the bundle ID of your app after saving it:
> mdls -name kMDItemCFBundleIdentifier /Applications/Zen\ PDF\ Viewer.app
> duti -s <BundleID> com.adobe.pdf all
> ```

---

### Windows

1. **Find `launch.bat`** in your cloned repo (e.g. `C:\Tools\zen-pdf-viewer\launch.bat`).

2. **Associate `.pdf` with the launcher** (run Command Prompt as Administrator):

   ```cmd
   assoc .pdf=ZenPDFFile
   ftype ZenPDFFile="C:\Tools\zen-pdf-viewer\launch.bat" "%1"
   ```

3. **Alternatively**, use the GUI:
   - Right-click any PDF → **Open with** → **Choose another app**
   - Scroll down and click **Look for another app on this PC**
   - Browse to `C:\Tools\zen-pdf-viewer\launch.bat` and select it
   - Check **Always use this app to open .pdf files**

4. **Make browsers open PDFs externally:**
   - **Edge**: Settings → Downloads → turn off "Open Office files in the browser" / PDF viewer
   - **Chrome**: Settings → Privacy and security → Site settings → Additional content settings → PDF documents → **Download PDFs**

---

## Usage

```bash
# Open a local file
zen-pdf-viewer /path/to/file.pdf

# Open a remote PDF (requires curl or wget on Linux/macOS)
zen-pdf-viewer https://example.com/document.pdf

# macOS / Windows equivalents
zen-pdf-viewer ~/Documents/file.pdf
.\launch.ps1 C:\Users\you\Documents\file.pdf
```

The launcher copies the PDF into a temporary directory, starts a local HTTP server on a random port bound to `127.0.0.1`, and opens the viewer URL in your default browser.

---

## Keyboard Shortcuts

| Key | Action |
|---|---|
| `J` / `PageDown` | Next page |
| `K` / `PageUp` | Previous page |
| `j` / `k` / `h` / `l` | Scroll down / up / left / right |
| `Arrow keys` | Scroll (same as h/j/k/l) |
| `Ctrl+d` / `Ctrl+u` | Half-page down / up |
| `Ctrl+t` / `Ctrl+y` | Half-page left / right |
| `Space` / `b` | Page down / page up |
| `g` | Go to first page |
| `G` | Go to last page |
| `1-9` | Go to bookmark slot (defaults to pages 1-9) |
| `Alt+1-9` | Assign the current viewport position to a bookmark slot |
| `:` | Go to page number (prompt) |
| `P` | Snap to nearest page |
| `H` / `L` | Scroll to top / bottom of current page |
| `Ctrl+o` / `Ctrl+i` | Jump backward / forward (jump list) |
| `Esc` | Open / close keybindings overlay |
| `r` | Rotate 90° |
| `z` | Toggle Zen reading filter (grayscale / invert) |
| `c` | Toggle color preservation in Zen mode |
| `d` | Toggle dual-page view |
| `p` | Toggle pageless transparent layout |
| `=` / `+` / `-` | Zoom in / out |
| `0` | Reset zoom to default width (portrait docs cap at ~120 DPI) |
| `w` | Fit page to window width |
| `R` | Reload document |
| `F11` | Toggle fullscreen |
| `q` | Quit / close tab |

---

## URL Parameters

You can also open the viewer directly in a browser without the launcher, or pass parameters manually:

```
http://127.0.0.1:PORT/viewer.html?file=doc.pdf&zen=1&imgcolor=0&page=42&fit=full
```

| Parameter | Default | Description |
|---|---|---|
| `file` | *(required)* | Filename served from the same local server |
| `zen` | `1` | Zen mode: `1` = enabled, `0` = disabled |
| `imgcolor` | `1` | Preserve image colors in Zen mode: `1` = keep (default), `0` = recolor |
| `dual` | `0` | Dual-page view: `1` = enabled |
| `pageless` | same as `zen` | Pageless/transparent mode: `1` = enabled |
| `page` | `1` | Open at this page number (1-based) |
| `fit` | `default` | Initial scale: `default` = portrait docs cap at ~120 DPI; `full` or `width` = fit page to window width (same as `w`) |
| `fullwidth` | `0` | Alias for `fit=full`: `1` or `true` |
| `svg` | `1` | Rendering backend preference: `1` = SVG-first (vector), `0` = force canvas |
| `fg` | `#e6e6e6` | Foreground/text color (URL-encoded hex) |

**Smart Page Caching:** Documents with ≤150 pages render all pages upfront on open and keep them in the DOM for instant scrolling. Larger documents use dynamic windowing to preserve memory. The viewer also applies a separate large-document optimization (reduced DPR and tighter windowing) when a document has ≥300 pages (controlled by `perf.largeDocPages` in `viewer.html`). The small-doc threshold is configurable (`perf.smallDocThreshold`).

---

## Theming & Customization

- Edit the `theme` object near the top of `viewer.html` to change default colors.
- The `state` object controls initial viewer mode. Query parameters always override the defaults.
- CSS lives in the embedded `<style>` block — the viewer is intentionally a single self-contained file.

### PDF.js version

The viewer pins **PDF.js 2.16.105** in `vendor/` (`pdf.min.js` and `pdf.worker.min.js`). Stay on the 2.x line: `SVGGraphics` (used for vector-first rendering) was removed in PDF.js v4, so bumping to current 4.x releases would break the default SVG path.

To refresh the vendored files after changing the pinned version:

1. Download matching `pdf.min.js` and `pdf.worker.min.js` from the [PDF.js releases page](https://github.com/mozilla/pdf.js/releases).
2. Replace the files in `vendor/`.
3. Re-copy `vendor/` to your viewer data directory (see [Installation](#installation)).

---

## How It Works

1. The **launcher** (`launch.sh` / `launch.ps1`) copies the requested PDF into a temporary directory alongside `viewer.html`, then starts `zen-server.py` bound to `127.0.0.1` on an ephemeral port (port 0 bind, no race). The server exits automatically after 30 minutes without requests.
2. **PDF.js** (bundled in `vendor/`) parses each page and renders it as **SVG by default** for vector-sharp browser/pinch zoom.
3. A **text layer** is rendered on top using `renderTextLayer`, making text selectable and copyable.
4. In **Zen mode with SVG backend**, a filter-based SVG path is used for dark rendering. This keeps SVG sharpness but may look different from the older pixel-heuristic Zen filter.
5. A high-DPI `<canvas>` path is still used when `svg=0` is set or when SVG rendering is unavailable.
6. A **display-scale debounce** (180 ms) watches window/viewport changes. Pinch-only viewport zoom avoids full rerender in SVG mode; layout changes rerender in place to reduce flashing. A **render token** ensures stale render passes are discarded when a new one starts.
7. **Smart page caching:** For documents with ≤150 pages, all pages are rendered upfront and kept in the DOM for instant scrolling. For larger documents (>150 pages), an LRU cache maintains up to 50 rendered pages in memory. New pages are added when scrolled into view, and the least recently used pages are unloaded when the cache exceeds the limit.

---

## Troubleshooting

**Blank or black pages**
Toggle Zen mode off (`z`) to check if the page renders normally. In Zen mode, near-white pixels become transparent — if the compositor does not composite correctly, the page may appear black.

**Text is not selectable**
Some PDFs are scanned images with no embedded text. Run OCR on the PDF first (e.g. `ocrmypdf input.pdf output.pdf`) to get a text layer.

**Cross-page selection stops at the page boundary**
Chrome-based browsers (and some Firefox versions) refuse to extend a native drag selection across `user-select: none` regions. The viewer bridges this with a pointer-driven `setBaseAndExtent` handler (`selBridge` in `bindEvents`): same-page drags stay fully native so empty-page-area drags behave predictably, and when the caret crosses into another page the selection is extended from the original anchor. If cross-page selection regresses, verify with a drag from page-1 text into page-2 text in pageless mode; the bridge relies on `document.caretPositionFromPoint` (Firefox) or `document.caretRangeFromPoint` (Chrome/Safari) both being present.

**"viewer.html not found" error**
The launcher cannot find `viewer.html` in the expected data directory. Re-run the copy step from the [Installation](#installation) section for your platform.

**Remote PDFs fail to load**
The launcher requires `curl` or `wget` on Linux/macOS. On Windows, `Invoke-WebRequest` is used. Make sure one of these is available and the URL is reachable.

**PDF.js worker fails to load**
Ensure `vendor/pdf.worker.min.js` was copied into the temp session (re-run the install step including `vendor/`). When testing from the repo with `python3 -m http.server`, serve from the repo root so `./vendor/` resolves correctly.

**SVG rendering falls back to canvas**
Some PDF.js bundles/browser combinations may not expose SVG rendering APIs. The viewer logs a console warning/error and falls back to canvas rendering automatically; use `svg=0` to force canvas explicitly.

**Zen mode looks different than before**
Zen recolor uses zathura-style lightness inversion (`recolor-keephue`) when color is enabled, with separate SVG handling for images vs vector text. Near-white paper and anti-aliased fringes are made transparent in pageless mode before recoloring.

**Server starts but browser does not open**
On Linux the launcher uses `xdg-open`; on macOS it uses `open`. If neither is available you will see an error. Copy the printed URL from the terminal and open it manually in any browser.

**Windows: PowerShell execution policy error**
Run `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` once in PowerShell, or use the `launch.bat` wrapper which passes `-ExecutionPolicy Bypass` automatically.

---

## Security & Privacy

- The HTTP server binds **only to `127.0.0.1`** — it is never reachable from the network.
- PDFs are copied into a temporary directory under `/tmp` (Linux/macOS) or `%TEMP%` (Windows) and served from there. The original file is never modified.
- PDF.js and its worker load from the bundled `vendor/` folder copied into each temp session — no external fetch at runtime.
- Temporary directories are left on disk after the viewer closes, but idle servers exit after 30 minutes. Clean temp dirs with `rm -rf /tmp/zen-pdf.*` on Linux/macOS or `Remove-Item $env:TEMP\zen-pdf-*` on Windows if disk space is a concern.

---

## Contributing

- Fork and open a PR with focused, descriptive commits.
- Keep `viewer.html` as a self-contained single file — no build step, no bundler.
- If you add or change URL parameters or keyboard shortcuts, update both `viewer.html` (the keybindings overlay table) and this README.
- Run the [manual test flow from AGENTS.md](AGENTS.md) before submitting.
