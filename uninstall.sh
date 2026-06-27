#!/bin/bash
#
#  Remove PocketSDR command-line tools and config presets installed by install.sh.
#
set -eu

BINDIR=/usr/local/bin
SHAREDIR=/usr/local/share/pocketsdr
ROOT="$(cd "$(dirname "$0")" && pwd)"

SUDO=""
if [ "$(id -u)" -ne 0 ]; then SUDO="sudo"; fi

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

if [ -d "$SHAREDIR" ]; then
    echo "removing $SHAREDIR"
    $SUDO rm -rf "$SHAREDIR"
fi

echo "Removed $removed tool(s) from $BINDIR and presets from $SHAREDIR"
