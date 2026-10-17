#!/usr/bin/env bash
# code.sh — start the local MakeCode editor on THIS project, in Chrome.
#
# `pxt serve` on its own serves the editor out of node_modules/pxt-microbit and
# opens the system default browser on an empty "My Projects" screen. This
# script fixes both: it links this repo into the server's workspace so the
# editor opens main.ts / main.blocks from disk (edits save straight back), and
# it opens Google Chrome, which is the only browser that can flash a micro:bit
# over WebUSB.
#
# Usage:
#   bash scripts/code.sh                 # serve on port 3232, open Chrome
#   bash scripts/code.sh --port 8080     # another port (websocket uses port+1)
#   bash scripts/code.sh --no-browser    # serve only, print the URL
#   BROWSER="Safari" bash scripts/code.sh
set -euo pipefail

PORT="${PORT:-3232}"
HOST="${HOST:-localhost}"
BROWSER="${BROWSER:-Google Chrome}"
OPEN_BROWSER=1

while [[ $# -gt 0 ]]; do
    case "$1" in
        --port) PORT="$2"; shift 2 ;;
        --host) HOST="$2"; shift 2 ;;
        --browser) BROWSER="$2"; shift 2 ;;
        --no-browser|--noBrowser) OPEN_BROWSER=0; shift ;;
        *) shift ;;
    esac
done
WSPORT=$((PORT + 1))

cd "$(dirname "$0")/.."
PROJECT_NAME="$(basename "$(pwd)")"

if [ ! -d node_modules/pxt-microbit ]; then
    echo "node_modules/pxt-microbit is missing. Run: npm install" >&2
    exit 1
fi
if [ ! -d pxt_modules ]; then
    echo "pxt_modules is missing. Run: pxt install" >&2
    exit 1
fi

# Refuse to start on top of another pxt server. pxt always wants 3232/3233, so
# a server left running in ANY project blocks this one with EADDRINUSE.
for p in "$PORT" "$WSPORT"; do
    if pids="$(lsof -nP -t -iTCP:"$p" -sTCP:LISTEN 2>/dev/null)" && [ -n "$pids" ]; then
        echo "Port $p is already in use by:" >&2
        ps -o pid=,command= -p "$pids" | cut -c1-160 >&2
        echo "Stop it with:  kill $pids" >&2
        exit 1
    fi
done

# The editor's filesystem workspace is <cwd>/projects/<name>. pxt creates the
# directory but never puts this project in it, so link the repo root in. The
# editor then reads pxt.json (extensions included), main.ts and main.blocks
# from disk and saves back to the same files.
mkdir -p projects
if [ ! -L "projects/$PROJECT_NAME" ]; then
    ln -sfn .. "projects/$PROJECT_NAME"
    echo "Linked projects/$PROJECT_NAME -> this repo"
fi

# Silence the "SUMMARY.md not found" spam. The target's docs/SUMMARY.md says
# "# @extends", which makes pxt look for the shared one under
# node_modules/pxt-microbit/node_modules/pxt-core/common-docs. npm flattened
# pxt-core up a level, so that path never exists. A symlink puts it back.
# (Lives in node_modules, so it is recreated here after every npm install.)
if [ -d node_modules/pxt-core ] && [ ! -e node_modules/pxt-microbit/node_modules/pxt-core ]; then
    mkdir -p node_modules/pxt-microbit/node_modules
    ln -s ../../pxt-core node_modules/pxt-microbit/node_modules/pxt-core
fi

# _history is MakeCode's undo log. A stale one bricks saving for the whole
# project: the server compares every file against the client's previous
# content and returns 409 for the entire save if any single file disagrees,
# after which the editor shows "Project Auto-Save Disabled" and silently stops
# persisting. A missing file skips that check, and the editor recreates it.
rm -f _history

# The local token authorises the editor's /api/* calls. pxt writes one into
# ~/.pxt/config.json on first serve; create it up front so the URL is complete.
PXT_CONFIG="${HOME}/.pxt/config.json"
mkdir -p "$(dirname "$PXT_CONFIG")"
LOCAL_TOKEN="$(node -e '
const fs = require("fs"), p = process.argv[1];
let c = {};
try { c = JSON.parse(fs.readFileSync(p, "utf8")); } catch (e) {}
if (!c.localToken) {
    c.localToken = require("crypto").randomUUID();
    fs.writeFileSync(p, JSON.stringify(c, null, 4) + "\n");
}
process.stdout.write(c.localToken);
' "$PXT_CONFIG")"

# .header.json gives the project a stable workspace id, which lets the URL jump
# straight to it (#header:<id>) instead of landing on the home screen.
HEADER_ID="$(node -e '
const fs = require("fs");
const cfg = JSON.parse(fs.readFileSync("pxt.json", "utf8"));
let h = {};
try { h = JSON.parse(fs.readFileSync(".header.json", "utf8")); } catch (e) {}
if (!h.id) {
    const now = Math.round(Date.now() / 1000);
    let targetVersion = "";
    try {
        targetVersion = JSON.parse(
            fs.readFileSync("node_modules/pxt-microbit/package.json", "utf8")
        ).version;
    } catch (e) {}
    h = {
        target: "microbit",
        targetVersion,
        name: cfg.name,
        meta: {},
        editor: cfg.preferredEditor || "tsprj",
        pubId: "",
        pubCurrent: false,
        _rev: null,
        id: require("crypto").randomUUID(),
        recentUse: now,
        modificationTime: now,
        cloudUserId: null,
        cloudCurrent: false,
        cloudVersion: null,
        cloudLastSyncTime: 0,
        isDeleted: false,
    };
    fs.writeFileSync(".header.json", JSON.stringify(h, null, 4) + "\n");
}
process.stdout.write(h.id);
')"

# ?ws=fs selects the FILESYSTEM workspace. Without it the editor keeps its own
# projects in the browser's IndexedDB and never asks this server for files.
# #header: must come before local_token, because the editor strips the token
# and everything after it. /index.html rather than /, because the redirect
# from / drops the query string.
EDITOR_URL="http://${HOST}:${PORT}/index.html?ws=fs#header:${HEADER_ID}&local_token=${LOCAL_TOKEN}&wsport=${WSPORT}"

echo "=== MakeCode local editor ==="
echo "    Project:  $PROJECT_NAME"
echo "    Files:    $(pwd)"
echo ""
echo "    $EDITOR_URL"
echo ""
echo "    Press Ctrl+C to stop."
echo ""

# Open the browser ourselves: pxt's own URL has no ?ws=fs and no #header:, so
# it always lands on an empty home screen. pxt gets --no-browser.
if [ "$OPEN_BROWSER" -eq 1 ]; then
    (
        for _ in $(seq 1 120); do
            nc -z "$HOST" "$PORT" 2>/dev/null && break
            sleep 0.5
        done
        if command -v open >/dev/null 2>&1; then
            open -a "$BROWSER" "$EDITOR_URL" 2>/dev/null || {
                echo "WARNING: '$BROWSER' not found; opening the default browser." >&2
                echo "         WebUSB flashing needs Chrome." >&2
                open "$EDITOR_URL"
            }
        elif command -v xdg-open >/dev/null 2>&1; then
            xdg-open "$EDITOR_URL"
        else
            echo "No browser opener found; open the URL above manually." >&2
        fi
    ) &
fi

PXT="pxt"
command -v pxt >/dev/null 2>&1 || PXT="npx --yes pxt"

# --just: serve the prebuilt editor from node_modules without trying to build
# the pxt-microbit target from source (that fails with "scandir 'libs'" in a
# project checkout, and then the browser hangs on the splash screen).
exec $PXT serve \
    --just \
    --localbuild \
    --noSerial \
    --hostname "$HOST" \
    --port "$PORT" \
    --wsport "$WSPORT" \
    --no-browser
