#!/usr/bin/env python3
"""Local HTTP server for Zen PDF Viewer with idle auto-exit."""
from __future__ import annotations

import argparse
import http.server
import os
import socketserver
import sys
import threading
import time

DEFAULT_IDLE_SECONDS = 30 * 60

last_activity = time.monotonic()
activity_lock = threading.Lock()


class QuietHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, format, *args):
        pass

    def finish(self):
        global last_activity
        with activity_lock:
            last_activity = time.monotonic()
        super().finish()


def idle_watchdog(idle_seconds: int) -> None:
    while True:
        time.sleep(60)
        with activity_lock:
            idle = time.monotonic() - last_activity
        if idle >= idle_seconds:
            os._exit(0)


def main() -> int:
    parser = argparse.ArgumentParser(description="Zen PDF Viewer local HTTP server")
    parser.add_argument("directory", help="Directory to serve")
    parser.add_argument("--port-file", required=True, help="Write the bound port here")
    parser.add_argument(
        "--idle-seconds",
        type=int,
        default=DEFAULT_IDLE_SECONDS,
        help="Exit after this many idle seconds (default: 1800)",
    )
    args = parser.parse_args()

    os.chdir(args.directory)
    threading.Thread(target=idle_watchdog, args=(args.idle_seconds,), daemon=True).start()

    class ReuseServer(socketserver.TCPServer):
        allow_reuse_address = True

    with ReuseServer(("127.0.0.1", 0), QuietHandler) as httpd:
        port = httpd.server_address[1]
        with open(args.port_file, "w", encoding="utf-8") as port_file:
            port_file.write(str(port))
        httpd.serve_forever()

    return 0


if __name__ == "__main__":
    sys.exit(main())
