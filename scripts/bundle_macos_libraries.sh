#!/bin/sh
# bundle_macos_libraries.sh - make a macOS app bundle self-contained: copy every library its
# executable needs from outside the system (Homebrew's cairo and what cairo pulls in) into
# Contents/Frameworks, point every reference at those copies, and re-sign them ad hoc. The
# app then runs on a Mac without Homebrew. Called by make_macos_app.sh.
#
# Usage:  sh scripts/bundle_macos_libraries.sh <path to the .app>
#
# Only tools that come with macOS: otool, install_name_tool, codesign.
set -eu

app=$1
exe_dir="$app/Contents/MacOS"
fw="$app/Contents/Frameworks"
mkdir -p "$fw"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
: > "$work/queue"      # bundled binary <TAB> where its original lives
: > "$work/done"

for exe in "$exe_dir"/*; do
	printf '%s\t%s\n' "$exe" "$exe" >> "$work/queue"
done

# The file a reference names, as the original binary at $2 would load it.
resolve() {
	ref=$1; origin=$2; origin_dir=$(dirname "$origin")
	case "$ref" in
		@rpath/*)
			name=${ref#@rpath/}
			for rp in $(otool -l "$origin" | awk '/cmd LC_RPATH/ {getline; getline; print $2}'); do
				dir=$(printf '%s' "$rp" | sed "s|@loader_path|$origin_dir|; s|@executable_path|$origin_dir|")
				if [ -e "$dir/$name" ]; then realpath "$dir/$name"; return; fi
			done
			if [ -e "$origin_dir/$name" ]; then realpath "$origin_dir/$name"; return; fi
			echo "bundle_macos_libraries.sh: cannot find $ref (needed by $origin)" >&2; exit 3 ;;
		@loader_path/*) realpath "$origin_dir/${ref#@loader_path/}" ;;
		@executable_path/*) echo "" ;;   # already bundled
		*) realpath "$ref" ;;
	esac
}

while [ -s "$work/queue" ]; do
	line=$(head -n 1 "$work/queue")
	tail -n +2 "$work/queue" > "$work/rest"; mv "$work/rest" "$work/queue"
	bin=$(printf '%s' "$line" | cut -f1)
	origin=$(printf '%s' "$line" | cut -f2)
	self_id=$(otool -D "$bin" | tail -n +2)
	otool -L "$bin" | tail -n +2 | sed 's/^[[:space:]]*//; s/ (compatibility.*//' | while read -r ref; do
		case "$ref" in /usr/lib/*|/System/*) continue ;; esac
		[ -n "$self_id" ] && [ "$ref" = "$self_id" ] && continue
		real=$(resolve "$ref" "$origin")
		[ -z "$real" ] && continue
		name=$(basename "$real")
		if [ ! -e "$fw/$name" ]; then
			cp "$real" "$fw/$name"
			chmod u+w "$fw/$name"
			install_name_tool -id "@executable_path/../Frameworks/$name" "$fw/$name" 2>/dev/null
			printf '%s\t%s\n' "$fw/$name" "$real" >> "$work/queue"
		fi
		install_name_tool -change "$ref" "@executable_path/../Frameworks/$name" "$bin" 2>/dev/null
	done
done

# Every copy is signed again (changing load commands breaks the old signature).
for lib in "$fw"/*.dylib; do
	[ -e "$lib" ] || continue
	codesign --force --sign - "$lib" >/dev/null 2>&1
done

# Nothing outside the system and the bundle is left.
left=$(for b in "$exe_dir"/* "$fw"/*.dylib; do otool -L "$b" | tail -n +2; done | sed 's/^[[:space:]]*//; s/ (compatibility.*//' \
	| grep -v '^/usr/lib/\|^/System/\|^@executable_path/' || true)
if [ -n "$left" ]; then
	echo "bundle_macos_libraries.sh: references left outside the bundle:" >&2
	printf '%s\n' "$left" >&2
	exit 4
fi
echo "$(ls "$fw" | wc -l | tr -d ' ') libraries bundled"
