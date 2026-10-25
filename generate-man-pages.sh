#!/bin/bash
#
#  Generate man pages from the doc/command_ref.md.
#
#  usage: generate-man-pages.sh [command_ref.md [out_dir]]
#
#  Each "## <cmd> - <summary>" section of the command reference becomes
#  <out_dir>/<cmd>.1. Prints the path of each page written. Needs pandoc.
#  Rerun after updating command_ref.md, then run install.sh 
#  to copy the man pages to system.

# Author: Minhaj Ahmad <mahmad12@crimson.ua.edu>

set -eu

ROOT="$(cd "$(dirname "$0")" && pwd)"
REF="${1:-$ROOT/doc/command_ref.md}"
OUT="${2:-$ROOT/doc/man}"

# convert one section (stdin) to man-ready markdown:
#   "## cmd - summary"  -> "# NAME" + "cmd - summary"
#   "### Heading"       -> "# HEADING"   (pandoc: .SH)
#   "- opt" + "  - txt" -> "opt" + ":   txt" (definition list, pandoc: .TP)
#   HTML anchors, page breaks and rules are dropped
to_man_md() {
    awk '
        /^<(a|div|br)/ || /^---$/ { next }
        /^## /  { sub(/^## /, ""); print "# NAME\n\n" $0; next }
        /^### / { print "# " toupper(substr($0, 5)); next }
        /^- /   { if (item != "") print item; item = $0; next }
        /^  - / && item != "" {
            print "\n" substr(item, 3) "\n:   " substr($0, 5); item = ""; next
        }
        { if (item != "") { print item; item = "" } print }
        END {
            if (item != "") print item
            print "\n# NOTES\n"
            print "This page is generated from doc/command_ref.md of PocketSDR by"
            print "generate-man-pages.sh. See doc/command_ref.md (or command_ref.pdf)"
            print "for the authoritative reference."
        }'
}

mkdir -p "$OUT"
for cmd in $(sed -n 's/^## \([A-Za-z0-9_]*\) - .*/\1/p' "$REF"); do
    awk -v cmd="$cmd" '
        $0 ~ "^## " cmd " - " { f = 1; print; next }
        f && /^## / { exit }
        f' "$REF" |
    to_man_md |
    pandoc -s -f markdown -t man --columns=200 -M title="$cmd" -M section=1 \
        -M header="Pocket SDR" |
    sed '/^\.TH /i .ds AD l' > "$OUT/$cmd.1"   # groff: left-align, no stretched cells
    echo "$OUT/$cmd.1"
done
