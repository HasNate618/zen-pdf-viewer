# Embed Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a first-class `embed=1` mode to zen-pdf-viewer so Campus (and other hosts) can iframe the viewer without maintaining a forked `viewer.html`.

**Architecture:** Keep the iframe embed model. Add URL params that toggle embed-specific keyboard handoff (`postMessage`), cookie-authenticated PDF fetches, and disabled standalone-only actions (`q`). Campus passes params on the iframe URL and drops its manual patches after re-vendoring.

**Tech Stack:** Single-file `viewer.html` (vanilla JS), Campus React iframe in `ContentPage.tsx`, static copy under `web/public/zen-pdf/`.

## Global Constraints

- No npm bundler or new dependencies in zen-pdf-viewer.
- All viewer logic stays in `viewer.html` unless a tiny sync script is added to Campus.
- `postMessage` target origin should be `window.location.origin` from the iframe (same-origin parent).
- Standalone launcher behavior must remain unchanged when `embed` is absent.
- PDF.js stays on **2.16.105** in `vendor/`.

---

## File map

| Repo | File | Change |
|------|------|--------|
| zen-pdf-viewer | `viewer.html` | Embed detection, postMessage, credentials, keybind branches |
| zen-pdf-viewer | `README.md` | Embed contract + Campus example URL |
| zen-pdf-viewer | `AGENTS.md` | Embed testing notes |
| Campus | `web/public/zen-pdf/viewer.html` | Re-vendor from upstream (delete fork) |
| Campus | `web/public/zen-pdf/vendor/` | Copy from upstream `vendor/` |
| Campus | `web/src/pages/ContentPage.tsx` | Add `embed=1`, origin check on messages |
| Campus | `web/public/zen-pdf/README.md` | Document sync + embed params |
| Campus | `scripts/vendor-zen-pdf.sh` (new) | One-command re-vendor |

---

## Phase 1 — zen-pdf-viewer embed API (~2–3 hours)

### Task 1: Embed detection helper

**Files:** `viewer.html`

- [ ] Parse `embed=1` (and alias `embedded=1` if desired) near other URL params.
- [ ] Add `const isEmbedded = params.get("embed") === "1";` (or small `parseEmbedParam()`).
- [ ] Parse `credentials=1` with default **`true` when `embed=1`**, else `false`.

**Verify:** Open `viewer.html?file=…` — behavior unchanged. Add `embed=1` — no visual change yet.

**Commit:** `Add embed and credentials URL param parsing`

---

### Task 2: postMessage helper

**Files:** `viewer.html`

- [ ] Add `notifyParent(type)` that calls:
  ```js
  if (window.parent !== window) {
    window.parent.postMessage({ type }, window.location.origin);
  }
  ```
- [ ] Only fire when `isEmbedded`.

**Verify:** In devtools console on embedded page, stub listener on parent — no messages until Task 3.

**Commit:** `Add embed postMessage helper`

---

### Task 3: Escape handoff

**Files:** `viewer.html` (keydown handler)

Current upstream: Escape always toggles keybind overlay.

- [ ] When `isEmbedded` and Escape:
  - If keybind overlay is **open** → close it (existing `toggleKeybinds` / `closeKeybinds`).
  - Else → `notifyParent('zenpdf-escape')`, preventDefault.
- [ ] When not embedded → keep current Escape/? behavior.

**Verify:** iframe on a test host page — Escape with overlay closed posts message; Escape with overlay open closes overlay only.

**Commit:** `Embed mode: Escape returns focus to parent`

---

### Task 4: Tab handoff

**Files:** `viewer.html` (keydown handler)

- [ ] When `isEmbedded` and Tab with **no user-assigned bookmarks** → `notifyParent('zenpdf-tab')`, preventDefault.
- [ ] When bookmarks exist → keep existing bookmark cycle.
- [ ] When not embedded → keep current Tab behavior.

**Verify:** Tab with no Alt+1-9 bookmarks posts message in embed mode.

**Commit:** `Embed mode: Tab returns focus to parent when no bookmarks`

---

### Task 5: Cookie-authenticated PDF fetch

**Files:** `viewer.html` (`init()` → `getDocument`)

- [ ] Replace hardcoded `withCredentials: false` with:
  ```js
  withCredentials: params.get("credentials") === "1" || isEmbedded,
  ```
  (Or stricter: only when `credentials=1` explicitly, with embed defaulting via param merge at parse time.)

**Verify:** Campus with `web_password` — PDF loads when `embed=1` and session cookie present.

**Commit:** `Embed mode: send credentials on PDF fetch`

---

### Task 6: Disable standalone quit in embed

**Files:** `viewer.html`

- [ ] When `isEmbedded`, `q` should no-op (or be ignored) — do not `window.close()` or navigate to `about:blank`.

**Verify:** `q` does nothing in iframe; still works standalone.

**Commit:** `Embed mode: disable q quit shortcut`

---

### Task 7: Documentation

**Files:** `README.md`, `AGENTS.md`

- [ ] README section **Embedding** with:
  - iframe example
  - param table: `embed`, `credentials`, plus existing `zen`, `pageless`, `page`, `fit`
  - postMessage contract:

    | Message type | When |
    |---|---|
    | `zenpdf-escape` | Escape pressed, keybind overlay closed |
    | `zenpdf-tab` | Tab pressed, no bookmark slots assigned |

- [ ] Parent listener example with `e.origin === window.location.origin`.
- [ ] AGENTS.md: manual test — load in iframe, verify Escape/Tab messages.

**Commit:** `Document embed mode and postMessage contract`

---

## Phase 2 — Campus integration (~2–3 hours)

### Task 8: Vendor sync script

**Files:** `Campus/scripts/vendor-zen-pdf.sh` (new)

- [ ] Copy from `$ZEN_PDF_ROOT` (or fixed relative path):
  - `viewer.html`
  - `zen-server.py` (optional, not used by Campus static serve)
  - `vendor/` directory
- [ ] Fail if diff would lose Campus-only files (there should be none after embed mode).
- [ ] Print reminder to rebuild / refresh PWA cache.

**Commit (Campus):** `Add zen-pdf vendor sync script`

---

### Task 9: Re-vendor viewer

**Files:** `Campus/web/public/zen-pdf/`

- [ ] Run sync script from Phase 1-complete zen-pdf-viewer.
- [ ] Confirm `./vendor/pdf.min.js` paths in `viewer.html` (not unpkg).
- [ ] Delete any fork-only patches (postMessage, selection color if upstream doesn't include it — **decide:** keep selection color in Campus CSS vs upstream; prefer Campus CSS if possible).

**Verify:** `/zen-pdf/viewer.html` loads offline (no unpkg in network tab).

**Commit (Campus):** `Re-vendor zen-pdf-viewer with embed mode`

---

### Task 10: Update ZenPdfFrame URL

**Files:** `Campus/web/src/pages/ContentPage.tsx`

- [ ] Add to `URLSearchParams`:
  ```ts
  embed: '1',
  // optional future:
  // zen: '0', pageless: '0', fit: 'full', page: String(startPage),
  ```
- [ ] Keep `t: fileId` for cache bust / remount.

**Verify:** PDF opens, Escape returns to sidebar, Tab returns to tree.

**Commit (Campus):** `Use official embed=1 zen-pdf URL param`

---

### Task 11: Harden postMessage listener

**Files:** `Campus/web/src/pages/ContentPage.tsx`

- [ ] Guard handler:
  ```ts
  if (e.origin !== window.location.origin) return
  if (e.source !== pdfFrameRef.current?.contentWindow) return
  ```
- [ ] Handle `zenpdf-escape` and `zenpdf-tab` as today.

**Commit (Campus):** `Validate zen-pdf postMessage origin and source`

---

### Task 12: Cleanup

**Files:** `Campus/web/package.json`, `web/public/zen-pdf/README.md`

- [ ] Remove unused `pdfjs-dist` npm dependency if still present.
- [ ] Update Campus vendored README: embed params, sync script, no manual fork steps.

**Commit (Campus):** `Remove unused pdfjs-dist dep and update zen-pdf docs`

---

## Phase 3 — Optional enhancements (later)

- [ ] **`embed=1` + default modes for Campus:** pass `zen=0&pageless=0&fit=full` when product wants non-Zen course reader.
- [ ] **Reading progress:** Campus stores last page per file id → passes `page=N`.
- [ ] **Blob URL fallback:** parent fetches `/api/files/{id}/raw` with credentials, passes `file=blob:…` if cookie forwarding ever fails cross-subdomain.
- [ ] **CI drift check:** Campus CI fails if `web/public/zen-pdf/viewer.html` sha differs from pinned zen-pdf-viewer tag.

---

## Test plan

### zen-pdf-viewer (standalone)

1. `python3 -m http.server 8000 --bind 127.0.0.1` from repo root.
2. Open `viewer.html?file=/tmp/doc.pdf` — Escape toggles keybinds; `q` quits.
3. Open host test page with iframe `?file=…&embed=1` — Escape posts message; `q` no-op.

### Campus

1. Open PDF in content pane — loads with session auth.
2. Focus iframe → Escape → sidebar zone.
3. Focus iframe → Tab (no bookmarks) → tree focus.
4. Mobile: iframe height still fills pane (regression on `global.css` unchanged).
5. Offline PWA: `/zen-pdf/*` serves from cache; PDF still network-fetches (expected).

---

## Suggested commit order

1. zen-pdf-viewer Phase 1 (tasks 1–7) — **one commit per task** or batched as 2 commits (code + docs).
2. Campus Phase 2 (tasks 8–12) — separate repo commits after upstream is tagged or synced.

**Estimated total:** ~1 day focused work across both repos.
