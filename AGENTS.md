# AGENT OPERATING GUIDE

## Purpose
Zen PDF Viewer is a local, keyboard-centric PDF player built from a single viewer page plus a lightweight launcher script.
The layout is intentionally minimal so agents should avoid introducing complex build chains or unnecessary dependencies.
This guide keeps attention on viewer.html's HTML, CSS, and embedded JavaScript as the primary editing surface.
Treat the README as the narrative for humans; the AGENTS file is for future agents that need practical guardrails.
Focus on stability, predictable DOM state, and clearly documented keybindings when you touch viewer logic.
Prioritize keyboard-first interactions, transparency-friendly styling, and quick response to scroll or input events.
When adding features, follow the existing zero-dependency mindset before suggesting vendored libraries.

## Workspace layout
viewer.html is the single UI entry point and holds the CSS, DOM skeleton, and event wiring for the viewer.
zen-server.py is the small idle-timeout HTTP server the launchers copy into each temp session.
README.md is the orientation reference; keep it up to date with any workflow changes you introduce.
The launcher helper lives outside git but the README describes how to install it under ~/.local/bin/zen-pdf-viewer.
Any new assets should live in a dedicated folder (suggested: vendor/ or assets/) so the repo stays organized.
Support files generated during runtime live in /tmp and must never be committed back into this repository.
Document new commands in README.md so users and other agents know how to run or test them.
Treat the repo as a standalone static bundle—there is no package manager, bundler, or installed framework today.
If a script is necessary, keep it small, shell-compatible, and comfortable for Python-based tooling.

## Commands
- Start the local HTTP preview server: `python3 -m http.server 8000 --bind 127.0.0.1` from the repo root.
- Use the launcher for integration: `zen-pdf-viewer /path/to/file.pdf` after making the script executable at ~/.local/bin/zen-pdf-viewer.
- Reload the viewer via `xdg-open http://127.0.0.1:8000/viewer.html?file=/tmp/doc.pdf` when testing manual tweaks.
- There is no build or lint pipeline, so keep tooling lightweight and document any new scripts you add.
- Locate fonts, CDN references, or other external resources in viewer.html before adding additional URLs.
- If you vendor PDF.js, keep `pdf.min.js` and `pdf.worker.min.js` in the same folder and update the workerSrc accordingly.
- The viewer pins PDF.js **2.16.105** on the 2.x line because `SVGGraphics` was removed in v4; do not bump to 4.x without replacing the SVG renderer.
- PDF.js loads from the bundled `vendor/` folder; launchers copy it into each temp session alongside `viewer.html`.

## Single-test flow
- Run `python3 -m http.server 8000 --bind 127.0.0.1` so the repo is served locally.
- In another terminal, copy a sample PDF to /tmp or point the viewer to a known path on the system.
- Open a browser and hit `http://127.0.0.1:8000/viewer.html?file=/tmp/doc.pdf&zen=1&imgcolor=0`.
- Verify that the keyboard shortcuts work (J/K for page navigation, z to toggle Zen mode, etc.).
- Confirm the text layer remains selectable by dragging a pointer across text elements.
- Watch for console errors related to PDF.js fetch or worker loading and note them in the review.
- **Test page caching behavior:** For small PDFs (≤150 pages), scroll through and verify pages remain rendered (no placeholders). For large PDFs (>150 pages), verify that an LRU cache of ~50 pages is maintained (inspect `getLoadedPages()` in console to see cache size and which pages are loaded).
- This flow counts as the single automated-ish test; capture any flakiness you see in the README.
- If a regression occurs, describe the steps in README.md so the next agent can reproduce it.
- Mention environmental assumptions (Linux desktop, Python 3 available) when you record the single test outcome.
- Keep in mind the server must be bound to 127.0.0.1 to avoid CORS issues.

## Manual verification tips
Always scroll through multiple pages in pageless mode to ensure caching is sane and rendering tokens are reset.
For small documents (≤150 pages), verify that scrolling does not cause any page unloading (check inspector or `state.renderedPages` in console).
For large documents (>150 pages), verify that the LRU cache maintains ~50 pages (call `getLoadedPages()` in console to inspect current cache state, which shows loaded pages and cache size).
To manually unload a specific page from the cache on a large document, call `unloadPage(pageNumber)` in the browser console to trigger explicit unload.
Rotate the document (press r) and ensure the viewport anchor is restored after renderAll runs.
Toggle dual-page mode with d and look for layout alignment issues; the CSS grid expects centered content.
Enable Zen mode, toggle color preservation (c), and check Zen rendering behaves as expected (SVG filter path or canvas fallback path).
Resize the browser window aggressively to trigger the resize debounce and verify SVG sharpness/canvas fallback DPI behavior stays appropriate.
Try page jumps via g and G to make sure the jump-back and jump-forward stacks behave predictably.
Use Alt+1-9 to save a bookmark slot and 1-9 to jump back to that position; verify the target still lands correctly after a resize.
Trigger the toast dismissal flow and make sure cookies suppress repeate invites; check the console for suppressed exceptions.
Open the keybind overlay (Esc) and ensure compactKeybindsTable still renders clean table markup.
Use pointer drags across the text layer to confirm selection logic naturally prevents jumps when leaving text.
Verify cross-page selection (page-1 text -> page-2 text in pageless mode) still bridges via the `selBridge` handler; same-page drags must remain fully native (no pointer override) so empty-area drags stay predictable.
Checking these paths manually is the most reliable regression guard because there are no automated suites.

## JavaScript style guidelines
- Prefer `const` for variables that never reassign and `let` for values that do; avoid `var` entirely.
- Wrap helper functions such as `renderPage` and `applyZenFilter` in the IIFE scope that already wraps the entire viewer.
- Keep indentation at two spaces, align object literals, and add trailing commas only where the surrounding code already uses them.
- Avoid module bundlers; keep the code inside viewer.html and ship as a single script tag per the existing pattern.
- Use descriptive names for state keys (e.g., `state.pdfDoc`, `state.renderToken`) and keep the `state` object centralized.
- Prefer `Math.max/min`, `clamp`, and helper functions over scattering magic numbers across the file.
- Minimize DOM queries by caching frequently used elements into consts near the top of the script.
- Annotate complex blocks with short comments when the behavior is non-obvious (e.g., pointer selection heuristics).
- Keep event listeners close to the logic they control, as seen in `bindEvents`, so behavior is easy to trace.
- When adding constants (colors, timing), define them near the top of the script to avoid duplication.

## CSS and layout guidelines
- Keep the global theme embedded in `<style>` so the viewer remains a single-file experience.
- Use `:root` and body styles sparingly to preserve the transparent background and color-scheme settings.
- Favor `display:flex` or CSS grid combinations similar to `.dual-mode` and `.pageless` for adaptive layouts.
- Avoid external stylesheets; if needed, add new rules close to existing ones while maintaining alphabetical order of selectors.
- Round borders subtly (6px-14px) per the existing page shell and toast styles to maintain the polished look.
- Reuse color values from the theme constants instead of sprinkling hex literals across new selectors.
- Keep overlay state toggles simple; prefer `hidden` attributes and `display:none` classes over complex CSS transitions.
- Any new animations should be lightweight and purposeful; avoid heavy motion that hampers keyboard navigation.
- Align text and controls using `gap`, `padding`, and `border-radius` conventions already present.
- Use backdrop-filter and rgba for depth, but be conservative to keep performance sane.

## HTML structure expectations
- Keep the body lean: the viewer container, overlays, toast, error, and render layers (SVG/canvas inside page shells) should remain the only top-level nodes.
- When adding overlays or modals, follow the existing pattern of a `.overlay` wrapper with a `.overlay-inner` child.
- Keep aria attributes and button labels descriptive to preserve accessibility for keyboard-only users.
- Avoid adding third-party embeds or inline scripts outside the PDF.js dependency that is already declared in viewer.html.
- If you need new controls, place them near the existing toolbar styles (even if the toolbar is currently hidden).
- Use `<div>` wrappers rather than tables for layout unless you purposefully recreate a grid like the keybinds table.
- Keep the keybind table consistent: each row should have `.keybind-key` and `.keybind-desc` cells.
- Title the page dynamically through metadata detection rather than hardcoding new titles in multiple spots.
- Keep the `#error` box hidden by default and show it only via JavaScript to avoid layout shifts.
- Avoid inline event attributes (e.g., onclick); attach listeners via `addEventListener` inside the script.

## Naming conventions
- Follow lowerCamelCase for functions and variables (e.g., `renderTextLayer`, `state.currentPage`).
- State object keys may use camelCase or descriptive names, but they should remain short and purposeful.
- CSS class names follow kebab-case; stick with that when adding new styles (e.g., `.page-shell`, `.zen-toast`).
- IDs should clearly map to singletons (`viewerContainer`, `zenToast`, `keybindsOverlay`).
- Constants in the script can use camelCase and should be grouped near the top (e.g., the `theme` object).
- When referencing query parameter keys, keep them lowercase and consistent with the launcher (zen, imgcolor, dual, pageless).
- Event handler names should describe the action (`handleGotoPagePrompt`, `compactKeybindsTable`).
- When adding new helper functions, place them near related logic, so the file flows top-down from general state to events.
- Keep boolean flags descriptive (`state.keepImagesColor`, `state.dualMode`) to avoid ambiguous toggles.
- Document any new naming decisions in AGENTS.md or README so future agents follow the same rhythm.

## Error handling and logging
- Wrap remote operations (PDF loading, metadata fetch) in try/catch and show human-facing errors using `showError`.
- When catching exceptions, log to the console only once so browser devtools stay readable without noise.
- Use `errorEl` to display failures instead of `alert`, and keep the message concise with actionable hints.
- Guard optional APIs before calling them (e.g., check `document.caretRangeFromPoint` exist before using it).
- When reading cookies or localStorage, catch and ignore security failures, matching the existing pattern in `bindEvents`.
- If you introduce new fetches, specify `withCredentials: false` unless absolutely required; maintain CORS safety.
- Avoid swallowing errors silently—if you must ignore an exception, add a short comment explaining why the failure is safe.
- Provide clear `console.error` messages with context so agents or humans can trace issues during manual tests.

## Debugging and observation
- Use `console.debug`, `console.info`, or `console.error` only when it will help during development; remove verbose logs before committing.
- When adjusting rendering logic, temporarily log `state.scale`, `state.rotation`, or render tokens to see how often they change.
- For layout regressions, inspect computed styles for `#viewerContainer` or `.pageShell` to verify new rules behave as expected.
- Keep an eye on `state.pageCache` size; clearing it before re-rendering prevents stale page data after zoom changes.
- When adding new keyboard shortcuts, describe them in the keybind overlay markup and make sure they fire immediately (there is no multi-key chord/combo window today).
- Run manual scroll tests to confirm `updateCurrentPageFromScroll` correctly updates `state.currentPage` after dynamic layout changes.
- Document any new instrumentation in README so future agents know what to expect from the JS console.
- If canvas filtering slows rendering, adjust `applyZenFilter` heuristics rather than adding heavy instrumentation.

## Documentation and comments
- Keep README.md and AGENTS.md aligned; mention significant feature changes or workflow updates in both places.
- Inline comments should explain why a block exists rather than what it does; the code should mostly speak for itself.
- When adding new keybindings, update the table in viewer.html and make sure the overlay text matches the actual behavior.
- Add narrative context to README if you introduce new URL parameters or theme options.
- New helper scripts or vendor files should include a brief usage blurb describing how to run them.
- Avoid rewriting README sections unless you are improving clarity; small tweaks are preferable to complete rewrites.
- Mention any manual testing steps in README so another agent can repeat the single-test flow reliably.
- Keep AGENTS.md at around 150 lines so future agents have a balanced but digestible reference.

## Automation and release notes
- There is no CI/CD configured, so treat the local Python server as the canonical smoke test runner.
- If you add automation, describe the command and its purpose in this AGENTS.md section along with prerequisites.
- Mention any dependencies (e.g., Python 3, browser) explicitly so onboarding is frictionless for other agents.
- Record the last manual test run timestamp in README or AGENTS.md when making significant UI updates.
- When prepping for releases, note whether CDN URLs or local vendor files should be locked to specific PDF.js versions.
- Keep track of which PDFs were used during verification so you can reproduce regressions later.
- If you introduce a new helper script, include platform compatibility notes (Linux targets only unless stated otherwise).
- Avoid merging automation that obscures manual debugging; preferring transparent CLI commands keeps the repo nimble.

## Cursor and Copilot rules
No `.cursor/rules/` directory exists in this repository today; there are no extra Cursor rules to follow.
There is no `.cursorrules` file either, so default CLI agent behavior is acceptable unless a future rule is added.
`.github/copilot-instructions.md` is absent, meaning there are no Copilot-specific guardrails to repeat in AGENTS.md.
If those files appear later, copy their content here or link back to them so this guide stays current.

## Final notes
Respect the minimal layout and keyboard-first ethos; when you add UI, keep it inline and consistent with the aesthetic.
Before submitting changes, re-run the single-test flow described above and update README/AGENTS accordingly.
Maintain a calm tone in comments and documentation—they should feel like a seasoned teammate briefing the next agent.
When in doubt, refer back to viewer.html's existing style and mirror it; radical departures deserve explicit justification.
