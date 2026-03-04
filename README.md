# Zen PDF Viewer

A lightweight, keyboard-first PDF viewer built on PDF.js. It runs entirely in your browser via a tiny local HTTP server — no Electron, no native app, no install wizard. One HTML file plus a launcher script is all it takes.

- **Zen mode** — grayscale + invert for comfortable dark reading, with optional image-color preservation
- **Pageless transparent rendering** — compositor blur/transparency (e.g. Hyprland) shows through the page background
- **High-DPI canvas** — respects `devicePixelRatio` for sharp output on retina/HiDPI screens
- **Selectable text** — PDF.js text layer lets you copy and search text in any PDF
- **Keyboard-first** — vim-style navigation, dual-page mode, zoom, rotation, jump list, and more
- **Cross-platform** — Linux, macOS, and Windows via the included launcher scripts

---

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
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
| **Internet** (optional) | PDF.js is loaded from a CDN by default; see [Offline / Vendored PDF.js](#offline--vendored-pdfjs) to avoid this |

---

## Installation

### Linux

1. **Clone the repository:**

   ```bash
   git clone https://github.com/HasNate618/zen-pdf-viewer.git ~/Projects/zen-pdf-viewer
   ```

2. **Copy `viewer.html` to the viewer data directory:**

   ```bash
   mkdir -p ~/.local/share/zen-pdf-viewer
   cp ~/Projects/zen-pdf-viewer/viewer.html ~/.local/share/zen-pdf-viewer/
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

2. **Copy `viewer.html` to the viewer data directory:**

   ```bash
   mkdir -p "$HOME/Library/Application Support/zen-pdf-viewer"
   cp ~/Projects/zen-pdf-viewer/viewer.html "$HOME/Library/Application Support/zen-pdf-viewer/"
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

2. **Copy `viewer.html` to the viewer data directory:**

   ```powershell
   $dest = "$env:APPDATA\zen-pdf-viewer"
   New-Item -ItemType Directory -Force $dest
   Copy-Item C:\Tools\zen-pdf-viewer\viewer.html $dest
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
| `gg` | Go to first page |
| `G` | Go to last page |
| `/` | Go to page number (prompt) |
| `P` | Snap to nearest page |
| `H` / `L` | Scroll to top / bottom of current page |
| `Ctrl+o` / `Ctrl+i` | Jump backward / forward (jump list) |
| `Esc` | Open / close keybindings overlay |
| `r` | Rotate 90° |
| `z` | Toggle Zen mode |
| `c` | Toggle color preservation in Zen mode |
| `d` | Toggle dual-page view |
| `p` | Toggle pageless + compression mode |
| `=` / `-` | Zoom in / out |
| `0` | Reset zoom to 100% |
| `R` | Reload document |
| `F11` | Toggle fullscreen |
| `q` | Quit / close tab |

---

## URL Parameters

You can also open the viewer directly in a browser without the launcher, or pass parameters manually:

```
http://127.0.0.1:PORT/viewer.html?file=doc.pdf&zen=1&imgcolor=0
```

| Parameter | Default | Description |
|---|---|---|
| `file` | *(required)* | Filename served from the same local server |
| `zen` | `1` | Zen mode: `1` = enabled, `0` = disabled |
| `imgcolor` | `0` | Preserve image colors in Zen mode: `1` = keep, `0` = recolor |
| `dual` | `0` | Dual-page view: `1` = enabled |
| `pageless` | same as `zen` | Pageless/transparent mode: `1` = enabled |
| `fg` | `#e6e6e6` | Foreground/text color (URL-encoded hex) |
| `bg` | `rgba(0,0,0,0.45)` | Toolbar background color |

---

## Theming & Customization

- Edit the `theme` object near the top of `viewer.html` to change default colors.
- The `state` object controls initial viewer mode. Query parameters always override the defaults.
- CSS lives in the embedded `<style>` block — the viewer is intentionally a single self-contained file.

### Offline / Vendored PDF.js

By default the viewer loads PDF.js from a CDN. To run fully offline:

1. Download `pdf.min.js` and `pdf.worker.min.js` from the [PDF.js releases page](https://github.com/mozilla/pdf.js/releases) (match the version in `viewer.html`).
2. Place them in a `vendor/` folder inside the repo.
3. In `viewer.html`, update:
   ```js
   // script src tag
   <script src="./vendor/pdf.min.js"></script>
   // inside the script
   pdfjsLib.GlobalWorkerOptions.workerSrc = './vendor/pdf.worker.min.js';
   ```

---

## How It Works

1. The **launcher** (`launch.sh` / `launch.ps1`) copies the requested PDF into a temporary directory alongside `viewer.html`, then starts `python3 -m http.server` bound to `127.0.0.1` on a randomly chosen free port.
2. **PDF.js** (loaded from CDN or vendored locally) parses the PDF and renders each page to a high-DPI `<canvas>` using `devicePixelRatio` for sharp output.
3. A **text layer** is rendered on top of each canvas using `renderTextLayer`, making text selectable and copyable.
4. If **Zen mode** is active, a pixel-level pass reads the canvas data, converts each pixel to grayscale and inverts it, and makes near-white backgrounds transparent in pageless mode. An optional heuristic skips colorful pixels to preserve image color.
5. A **resize debounce** (180 ms) re-scales and re-renders the entire document when the window size changes. A **render token** ensures stale render passes are discarded when a new one starts.

---

## Troubleshooting

**Blank or black pages**
Toggle Zen mode off (`z`) to check if the page renders normally. In Zen mode, near-white pixels become transparent — if the compositor does not composite correctly, the page may appear black.

**Text is not selectable**
Some PDFs are scanned images with no embedded text. Run OCR on the PDF first (e.g. `ocrmypdf input.pdf output.pdf`) to get a text layer.

**"viewer.html not found" error**
The launcher cannot find `viewer.html` in the expected data directory. Re-run the copy step from the [Installation](#installation) section for your platform.

**Remote PDFs fail to load**
The launcher requires `curl` or `wget` on Linux/macOS. On Windows, `Invoke-WebRequest` is used. Make sure one of these is available and the URL is reachable.

**PDF.js worker fails to load**
A network block or content-security policy may prevent the CDN worker from loading. See [Offline / Vendored PDF.js](#offline--vendored-pdfjs) to serve the worker locally.

**Server starts but browser does not open**
On Linux the launcher uses `xdg-open`; on macOS it uses `open`. If neither is available you will see an error. Copy the printed URL from the terminal and open it manually in any browser.

**Windows: PowerShell execution policy error**
Run `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` once in PowerShell, or use the `launch.bat` wrapper which passes `-ExecutionPolicy Bypass` automatically.

---

## Security & Privacy

- The HTTP server binds **only to `127.0.0.1`** — it is never reachable from the network.
- PDFs are copied into a temporary directory under `/tmp` (Linux/macOS) or `%TEMP%` (Windows) and served from there. The original file is never modified.
- By default, PDF.js and its worker are fetched from `unpkg.com`. Vendor them locally (see above) for fully offline or air-gapped use.
- Temporary directories are left on disk after the viewer closes. Clean them up with `rm -rf /tmp/zen-pdf.*` on Linux/macOS or `Remove-Item $env:TEMP\zen-pdf-*` on Windows if disk space is a concern.

---

## Contributing

- Fork and open a PR with focused, descriptive commits.
- Keep `viewer.html` as a self-contained single file — no build step, no bundler.
- If you add or change URL parameters or keyboard shortcuts, update both `viewer.html` (the keybindings overlay table) and this README.
- Run the [manual test flow from AGENTS.md](AGENTS.md) before submitting.
