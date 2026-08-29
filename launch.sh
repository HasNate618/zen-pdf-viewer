#!/usr/bin/env bash
# Zen PDF Viewer launcher — Linux & macOS
# Usage: launch.sh <file-or-url>
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: zen-pdf-viewer <file-or-url>" >&2
  exit 1
fi

arg="$1"
if [ $# -gt 1 ]; then
  arg="$*"
fi

# --- helpers -----------------------------------------------------------------

urlencode() {
  python3 - "$1" <<'PY'
import sys, urllib.parse
print(urllib.parse.quote(sys.argv[1], safe=''))
PY
}

# realpath -f is Linux-only; use Python for portability on macOS
realpath_x() {
  python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$1"
}

# Detect the command used to open URLs / files in the default browser
if command -v xdg-open >/dev/null 2>&1; then
  OPEN_CMD="xdg-open"
elif command -v open >/dev/null 2>&1; then
  OPEN_CMD="open"
else
  echo "No browser opener found (expected xdg-open on Linux or open on macOS)" >&2
  exit 1
fi

# --- locate viewer -----------------------------------------------------------

# Nix and manual installs can override the data directory.
PDFJS_DIR="${ZEN_PDF_VIEWER_DATA_DIR:-$HOME/.local/share/zen-pdf-viewer}"
if [ ! -f "$PDFJS_DIR/viewer.html" ] && [ -d "$HOME/Library" ]; then
  PDFJS_DIR="$HOME/Library/Application Support/zen-pdf-viewer"
fi

if [ ! -f "$PDFJS_DIR/viewer.html" ]; then
  echo "viewer.html not found at $PDFJS_DIR/viewer.html" >&2
  echo "Run the install step from the README and try again." >&2
  exit 1
fi

SERVER_PY="$PDFJS_DIR/zen-server.py"
if [ ! -f "$SERVER_PY" ]; then
  echo "zen-server.py not found at $SERVER_PY" >&2
  echo "Run the install step from the README and try again." >&2
  exit 1
fi

# --- temp dir ----------------------------------------------------------------

TMPDIR=$(mktemp -d /tmp/zen-pdf.XXXXXX) || exit 1
cp -a "$PDFJS_DIR/viewer.html" "$TMPDIR/" || {
  echo "Failed to copy viewer.html" >&2
  rm -rf "$TMPDIR"
  exit 1
}
cp -a "$SERVER_PY" "$TMPDIR/" || {
  echo "Failed to copy zen-server.py" >&2
  rm -rf "$TMPDIR"
  exit 1
}

# --- resolve PDF -------------------------------------------------------------

tmp_pdf="$TMPDIR/doc.pdf"
case "$arg" in
  http://*|https://*)
    if command -v curl >/dev/null 2>&1; then
      curl -L --fail --silent --show-error -o "$tmp_pdf" "$arg" \
        || { echo "curl failed to download $arg" >&2; rm -rf "$TMPDIR"; exit 1; }
    elif command -v wget >/dev/null 2>&1; then
      wget -q -O "$tmp_pdf" "$arg" \
        || { echo "wget failed to download $arg" >&2; rm -rf "$TMPDIR"; exit 1; }
    else
      echo "No curl or wget found; cannot download remote PDFs" >&2
      rm -rf "$TMPDIR"; exit 1
    fi
    ;;
  file://*)
    fp="${arg#file://}"
    fp="$(realpath_x "$fp")"
    cp -a "$fp" "$tmp_pdf" \
      || { echo "Failed to copy $fp" >&2; rm -rf "$TMPDIR"; exit 1; }
    ;;
  *)
    fp="$(realpath_x "$arg")"
    cp -a "$fp" "$tmp_pdf" \
      || { echo "Failed to copy $fp" >&2; rm -rf "$TMPDIR"; exit 1; }
    ;;
esac

# --- start the server (binds port 0 directly; no TOCTOU race) ---------------

PORT_FILE="$TMPDIR/port"
nohup python3 "$TMPDIR/zen-server.py" "$TMPDIR" --port-file "$PORT_FILE" \
  >/dev/null 2>&1 &
SERVER_PID=$!

PORT=""
for _ in $(seq 1 30); do
  if [ -f "$PORT_FILE" ]; then
    PORT=$(cat "$PORT_FILE")
    break
  fi
  sleep 0.1
done

if [ -z "$PORT" ]; then
  echo "Local viewer server did not report a port in time" >&2
  exit 1
fi

# Wait until the server is up (up to 3 s).
ready=0
for _ in $(seq 1 30); do
  if python3 -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:$PORT/viewer.html', timeout=1)" >/dev/null 2>&1; then
    ready=1; break
  fi
  sleep 0.1
done

if [ "$ready" -ne 1 ]; then
  echo "Local viewer server did not start in time" >&2
  exit 1
fi

# --- open browser ------------------------------------------------------------

enc_file=$(urlencode "doc.pdf")
enc_fg=$(urlencode "#e6e6e6")
URL="http://127.0.0.1:$PORT/viewer.html?file=$enc_file&zen=1&fg=$enc_fg"

$OPEN_CMD "$URL" >/dev/null 2>&1 &
printf 'Zen PDF viewer: %s  (server pid %s, tmpdir %s)\n' "$URL" "$SERVER_PID" "$TMPDIR" >&2
exit 0
