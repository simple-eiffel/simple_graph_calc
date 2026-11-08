#!/bin/sh
# Regenerate src/expression/gc_parser.e from grammar/gc_parser.y with Gobo's geyacc.
# The generated file is committed, so building the calculator never needs geyacc.
set -e
cd "$(dirname "$0")/.."
GEYACC="${GEYACC:-/c/Program Files/Eiffel Software/EiffelStudio 25.02 Standard/library/gobo/spec/win64/bin/geyacc.exe}"
"$GEYACC" --version
"$GEYACC" -x -o src/expression/gc_parser.e grammar/gc_parser.y
echo "generated src/expression/gc_parser.e"
