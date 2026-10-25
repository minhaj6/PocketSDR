#!/bin/bash
#
#  Remove PocketSDR command-line tools and config presets installed by install.sh.
#
#
# Author: Minhaj Ahmad <mahmad12@crimson.ua.edu>

set -eu

BINDIR=/usr/local/bin
SHAREDIR=/usr/local/share/pocketsdr
MANDIR=/usr/local/share/man/man1
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

# man pages installed from doc/man
for f in "$ROOT"/doc/man/*.1; do
    target="$MANDIR/$(basename "$f")"
    if [ -e "$target" ]; then
        echo "removing $target"
        $SUDO rm -f "$target"
    fi
done

COMP=/usr/share/bash-completion/completions/pocket_conf
if [ -e "$COMP" ]; then
    echo "removing $COMP"
    $SUDO rm -f "$COMP"
fi

echo "Removed $removed tool(s) from $BINDIR and presets from $SHAREDIR"
