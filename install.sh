#!/bin/bash
#
#  Install PocketSDR command-line tools system-wide.
#
#  Build them first:   make -C app
#
#  Usage:
#    ./install.sh                        install to /usr/local/bin (default)
#    PREFIX=/opt/pocketsdr ./install.sh  install to /opt/pocketsdr/bin
#
set -eu

PREFIX="${PREFIX:-/usr/local}"
BINDIR="$PREFIX/bin"
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

# elevate only when the destination isn't writable
SUDO=""
if [ "$(id -u)" -ne 0 ] && [ ! -w "$PREFIX" ]; then SUDO="sudo"; fi

$SUDO mkdir -p "$BINDIR"
$SUDO make -C "$ROOT/app" install BIN="$BINDIR"
echo "Installed $built tool(s) to $BINDIR"
