#!/bin/bash
#
#  Remove PocketSDR command-line tools installed by install.sh.
#
#  Usage:
#    ./uninstall.sh                        remove from /usr/local/bin (default)
#    PREFIX=/opt/pocketsdr ./uninstall.sh  remove from /opt/pocketsdr/bin
#
set -eu

PREFIX="${PREFIX:-/usr/local}"
BINDIR="$PREFIX/bin"
ROOT="$(cd "$(dirname "$0")" && pwd)"

# elevate only when the destination isn't writable
SUDO=""
if [ "$(id -u)" -ne 0 ] && [ ! -w "$BINDIR" ]; then SUDO="sudo"; fi

# tool names = extensionless executables built under app/*/ (matches install)
removed=0
for f in "$ROOT"/app/*/*; do
    b="$(basename "$f")"
    if [ -f "$f" ] && [ -x "$f" ] && [[ "$b" != *.* ]]; then
        target="$BINDIR/$b"
        if [ -e "$target" ]; then
            echo "removing $target"
            $SUDO rm -f "$target"
            removed=$((removed + 1))
        fi
    fi
done
echo "Removed $removed tool(s) from $BINDIR"
