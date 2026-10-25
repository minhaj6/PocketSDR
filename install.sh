#!/bin/bash
#
#  Install PocketSDR command-line tools and config presets system-wide.
#
#  Build them first:   make -C app
#
#    binaries -> /usr/local/bin
#    presets  -> /usr/local/share/pocketsdr/conf
#    web UI   -> /usr/local/share/pocketsdr/html  (served by pocket_web)
#
set -eu

BINDIR=/usr/local/bin
CONFDIR=/usr/local/share/pocketsdr/conf
HTMLDIR=/usr/local/share/pocketsdr/html
ROOT="$(cd "$(dirname "$0")" && pwd)"

# install only copies binaries -- make sure they were built first.
built=0
for f in "$ROOT"/app/*/*; do
    b="$(basename "$f")"
    if [ -f "$f" ] && [ -x "$f" ] && [[ "$b" != *.* ]]; then
        built=$((built + 1))
    fi
done
if [ "$built" -eq 0 ]; then
    echo "error: no built tools under app/ -- run 'make -C app' first" >&2
    exit 1
fi

SUDO=""
if [ "$(id -u)" -ne 0 ]; then SUDO="sudo"; fi

# binaries
$SUDO mkdir -p "$BINDIR"
$SUDO make -C "$ROOT/app" install BIN="$BINDIR"

# config presets
$SUDO mkdir -p "$CONFDIR"
$SUDO cp "$ROOT"/conf/*.conf "$CONFDIR"/

# web UI files for pocket_web (replace, so files removed upstream go away)
$SUDO rm -rf "$HTMLDIR"
$SUDO cp -r "$ROOT/html" "$HTMLDIR"

# bash completion (only if the bash-completion framework is installed)
COMPDIR=/usr/share/bash-completion/completions
if [ -d "$COMPDIR" ]; then
    $SUDO cp "$ROOT/completion/pocket_conf" "$COMPDIR/pocket_conf"
    echo "Installed bash completion to $COMPDIR/pocket_conf"
else
    echo "bash-completion not found; skipped (script kept at completion/pocket_conf)"
fi

echo "Installed $built tool(s) to $BINDIR, presets to $CONFDIR and web UI to $HTMLDIR"
