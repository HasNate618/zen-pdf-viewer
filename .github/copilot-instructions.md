# Copilot Instructions for Zen PDF Viewer

This file provides actionable guidance for Copilot and other AI agents working in this repository. For full context on project philosophy and manual testing procedures, see [AGENTS.md](../AGENTS.md).

## Project Overview

Zen PDF Viewer is a single-file, keyboard-first PDF viewer built on PDF.js and served via a minimal Python HTTP server. The entire viewer lives in `viewer.html` (1230 lines of HTML, CSS, and JavaScript) with launcher scripts for Linux, macOS, and Windows that handle file transfer and server startup. There is no build step, bundler, or package manager — the repository is designed to ship as a static artifact.

## Build, Test, and Development

**No linters, bundlers, or automated tests exist.** Development and verification are manual:

### Starting the Development Server

```bash
python3 -m http.server 8000 --bind 127.0.0.1
```

Runs from the repo root and serves on `http://127.0.0.1:8000`. The server must bind to `127.0.0.1` to avoid CORS issues with PDF.js.

### Manual Verification (Single-Test Flow)

1. Start the server in one terminal.
2. Copy a test PDF to `/tmp` or locate one on disk.
3. Open browser: `http://127.0.0.1:8000/viewer.html?file=/tmp/doc.pdf&zen=1&imgcolor=0`
4. Verify keyboard shortcuts (J/K for pages, Z for Zen mode, etc.) respond correctly.
5. Confirm text remains selectable by dragging across text elements.
6. Check browser console for errors (especially PDF.js worker loading).
7. Test mode transitions:
   - Scroll through pageless mode to verify rendering token cleanup.
   - Rotate (press `r`) and check viewport anchor restoration.
   - Toggle dual-page mode (`d`) for layout alignment.
   - Resize aggressively to trigger debounce and verify scaling.

This manual flow is the only regression guard; capture any issues in README.md for future agents to reproduce.

### Testing New Changes

After editing `viewer.html`:

- Reload `http://127.0.0.1:8000/viewer.html?file=...` in the browser (hard-refresh if needed).
- Monitor the browser console for errors.
- Manually test affected keyboard shortcuts and UI modes.
- If modifying rendering logic, check `state.scale`, `state.rotation`, and `state.pageCache` in console.
- Document any new keybindings in the overlay table and README.md.

### Optional: Vendored PDF.js (Offline Use)

To avoid CDN dependency:

1. Download `pdf.min.js` and `pdf.worker.min.js` from [PDF.js releases](https://github.com/mozilla/pdf.js/releases).
2. Place them in a `vendor/` folder.
3. Update script src and `workerSrc` in `viewer.html` to point to `./vendor/`.

## Architecture

### Single-File Design

The entire viewer is one HTML file with embedded CSS and JavaScript wrapped in an IIFE (immediately invoked function expression). This ensures:

- **No external dependencies** beyond PDF.js (from CDN or vendored locally).
- **Self-contained state** managed via a centralized `state` object (page, scale, rotation, etc.).
- **Event-driven DOM** with listeners attached via `bindEvents()` rather than inline attributes.
- **Transparent background** support for desktop compositors (Linux Hyprland, macOS, etc.).

### Key Modules and Functions

| Function/Object | Purpose |
|---|---|
| `state` | Centralized mutable state (current page, zoom, rotation, mode flags, page cache, render token). |
| `theme` | Color constants (foreground, background, etc.) applied globally and through Zen filter. |
| `params` | URL query parameters (file, zen, dual, pageless, imgcolor, fg, bg). |
| `renderPage(pageNum)` | Render a single page to canvas with Zen filter if enabled; caches in `state.pageCache`. |
| `applyZenFilter(ctx, w, h, keepImagesColor)` | Pixel-level grayscale + invert transformation; preserves colors if `keepImagesColor` is true. |
| `renderAll()` | Re-render all visible pages (called on mode/zoom/rotation changes); uses `state.renderToken` to discard stale passes. |
| `updateCurrentPageFromScroll()` | Update `state.currentPage` based on scroll position (calls `updateToolbar()` to reflect UI). |
| `bindEvents()` | Attach all keyboard and pointer listeners; handles vim-style navigation, jump stacks, etc. |
| `showError(message)` | Display human-facing error in overlay; log to console. |
| `startTransition() / endTransition()` | Show/hide fade-in overlay during expensive operations. |
| `compactKeybindsTable()` | Generate keybind overlay table from inline markup. |
| `adjustScaleToMode()` | Auto-scale based on layout mode (dual, pageless, fullscreen). |

### CSS Organization

CSS is embedded in a `<style>` block and organized by selector. Key classes:

- `.page-shell` — Container for each rendered page.
- `.textLayer` — PDF.js text layer (selectable text).
- `.dual-mode` — CSS grid for side-by-side pages.
- `.pageless` — Vertical scroll with transparent background.
- `.zen-toast` — Toast notification (Zen mode toggled).
- `.overlay`, `.overlay-inner` — Modal containers (keybinds, errors, transitions).
- `#transitionOverlay` — Fade overlay during render operations.

### HTML Structure

```
#viewerContainer (main container)
├── #viewerContent (scrollable area)
│   └── [page shells, dynamically rendered]
├── #zenToast (notification)
├── #error (error overlay)
├── #keybindsOverlay (help modal)
│   └── keybinds table
└── #transitionOverlay (fade-in during expensive ops)
```

## Key Conventions

### Naming

- **Functions:** lowerCamelCase (`renderPage`, `applyZenFilter`, `handleGotoPagePrompt`).
- **State keys:** descriptive lowerCamelCase (`state.currentPage`, `state.renderToken`, `state.keepImagesColor`).
- **CSS classes:** kebab-case (`.page-shell`, `.dual-mode`, `.zen-toast`).
- **IDs:** singletons in camelCase (`viewerContainer`, `keybindsOverlay`, `transitionOverlay`).
- **URL params:** lowercase (`zen`, `dual`, `pageless`, `imgcolor`, `fg`, `bg`).

### State Management

- Keep `state` centralized at the top of the script; avoid module patterns.
- Use `state.renderToken` to invalidate stale render passes when mode/zoom/rotation changes.
- Clear `state.pageCache` before `renderAll()` to prevent stale page data.
- Boolean flags: `state.dualMode`, `state.pagelessMode`, `state.keepImagesColor` (descriptive, not ambiguous).

### Keyboard Shortcuts and Combos

- Vim-style keys: `j`/`k` (scroll down/up), `h`/`l` (scroll left/right), `gg` (first page), `G` (last page).
- Combo window: 800ms between keystrokes for multi-key sequences like `gg`.
- Toggle keys: `z` (Zen), `d` (dual), `p` (pageless), `c` (color preservation), `r` (rotate).
- Modal keys: `Esc` (keybinds overlay), `q` (quit/close tab).
- All shortcuts must be documented in the keybinds overlay table and README.md.

### Rendering and Performance

- `renderPage()` handles a single page; `renderAll()` re-renders visible pages.
- Use `state.renderToken` to discard render passes started before a newer mode change (prevents flickering).
- Resize is debounced at 180ms; triggers `adjustScaleToMode()` and `renderAll()`.
- High-DPI support via `devicePixelRatio`; canvas is scaled internally but CSS size remains consistent.
- Zen filter is applied pixel-by-pixel in `applyZenFilter()`; heuristic skips colorful pixels if `keepImagesColor` is true.

### Error Handling

- Wrap remote operations (PDF loading, metadata fetch) in try/catch.
- Use `showError()` for user-facing messages; avoid `alert()`.
- Log to console only once per error (avoid noise in devtools).
- Guard optional APIs (e.g., `document.caretRangeFromPoint`) before calling.
- Fetch without credentials (`withCredentials: false`) unless required; maintain CORS safety.

### DOM and Layout

- Avoid inline event attributes; use `addEventListener` inside `bindEvents()`.
- Use flexbox and CSS grid (`.dual-mode`, `.pageless` are examples).
- Keep overlays as `.overlay` wrapper with `.overlay-inner` child.
- Preserve transparent background with `background: rgba(0,0,0,0)` or similar in Zen mode.
- Use `hidden` attribute or `display:none` class for modal toggles (simple, no complex transitions).

### Code Style

- 2-space indentation.
- Prefer `const` (never reassign) over `let` (reassign) over `var` (never use).
- Trailing commas only where surrounding code already uses them.
- Inline comments explain *why* a block exists, not what it does.
- Keep helper functions near related logic so behavior is traceable top-down.

## When to Edit

### Adding or Modifying Features

1. **Understand the existing state and flow** by reading relevant sections in `viewer.html` (search for the function or state key involved).
2. **Make changes inline** in viewer.html; avoid external files unless necessary (e.g., vendor assets).
3. **Update keybinds table** (HTML markup in viewer.html) if adding keyboard shortcuts.
4. **Update README.md** if adding URL parameters, new modes, or changing behavior.
5. **Update AGENTS.md** if introducing new conventions or architectural patterns.
6. **Run manual verification flow** (dev server + browser test) and document any regressions in README.md.

### Common Tasks

- **Add a keyboard shortcut:** Edit `bindEvents()`, add handler logic, update keybinds table and README.
- **Change a color:** Edit `theme` object near top of script; Zen filter adjusts colors automatically.
- **Adjust rendering logic:** Edit `renderPage()` or `applyZenFilter()`; test with high-zoom and rotation.
- **Add a UI mode:** Add state flag (`state.newMode`), update `renderAll()` and CSS classes, test layout changes.
- **Fix a layout issue:** Check CSS grid/flex rules and test aggressive window resizing (180ms debounce).

## Troubleshooting

| Issue | Investigation |
|---|---|
| Blank or black pages in Zen mode | Toggle Zen off (`z`) to check if page renders normally. Check if compositor composites correctly. |
| Text not selectable | Some PDFs are scanned images with no text layer. Run OCR (e.g., `ocrmypdf`) first. |
| PDF.js worker fails to load | Network block or CSP may prevent CDN fetch. Vendor PDF.js locally. |
| Console errors on render | Check `state.renderToken` is invalidated correctly on mode changes; inspect `state.pageCache`. |
| Keyboard shortcuts unresponsive | Verify 800ms combo window; check if `bindEvents()` listener is attached; inspect console for JS errors. |
| Layout breaks on resize | Check CSS grid/flex breakpoints; verify `adjustScaleToMode()` is triggered; test with browser dev tools. |

## Documentation References

- **README.md** — User-facing guide: installation, shortcuts, URL parameters, troubleshooting.
- **AGENTS.md** — Detailed agent guide: manual testing, style conventions, naming, DOM structure, debugging.
- **This file** — High-level guidance for Copilot: build commands, architecture, conventions, when to edit.

Keep all three files in sync when making significant changes. Prefer small, focused edits over large rewrites.

## External Dependencies

- **PDF.js** (v3+, default from unpkg.com CDN) — Parse and render PDFs.
- **Python 3** (for local dev server) — Runs `python3 -m http.server 8000 --bind 127.0.0.1`.
- **curl or wget** (Linux/macOS) — Used by launchers to download remote PDFs.
- **Browser** — Must support PDF.js (Chrome, Firefox, Safari, Edge, Zen Browser).

No npm, pip, or other package managers are used. Keep it this way.
