#!/bin/sh
# make_macos_app.sh - wrap a finalized simple_graph_calc executable in a macOS app bundle,
# so the calculator opens from Finder, the Dock or Spotlight like any Mac application.
#
# Usage:  sh scripts/make_macos_app.sh <finalized executable> [output folder]
#         (the output folder defaults to ./dist)
#
# It uses only tools that come with macOS: sips and iconutil for the icon, plutil to check
# Info.plist, codesign for the ad-hoc signature Apple silicon requires. The bundle runs on
# Macs that have the same Homebrew libraries (cairo and its friends); bundling those, and a
# Developer ID signature for other people's Macs, are later steps.
set -eu

if [ "$(uname -s)" != "Darwin" ]; then
	echo "make_macos_app.sh: this builds a macOS bundle; run it on a Mac." >&2
	exit 2
fi
if [ $# -lt 1 ] || [ ! -x "$1" ]; then
	echo "usage: sh scripts/make_macos_app.sh <finalized executable> [output folder]" >&2
	exit 2
fi

here=$(cd "$(dirname "$0")/.." && pwd)
exe=$1
out=${2:-dist}
name="Eiffel Graphing Calculator"
app="$out/$name.app"
version="0.1"

mkdir -p "$out"
# Replace only our own bundle.
case "$app" in
	*.app) rm -rf "$app" ;;
esac
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
# One folder per language the app speaks: Finder's "Get Info" and the system read these, even
# empty (the calculator chooses its words itself).
mkdir -p "$app/Contents/Resources/en.lproj" "$app/Contents/Resources/he.lproj"
cp "$exe" "$app/Contents/MacOS/simple_graph_calc"

# The icon: every size macOS asks for, from the 1024 px master.
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
set_dir="$work/AppIcon.iconset"
mkdir "$set_dir"
for size in 16 32 128 256 512; do
	sips -z $size $size "$here/packaging/macos/app_icon_1024.png" --out "$set_dir/icon_${size}x${size}.png" >/dev/null
	double=$((size * 2))
	sips -z $double $double "$here/packaging/macos/app_icon_1024.png" --out "$set_dir/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$set_dir" -o "$app/Contents/Resources/AppIcon.icns"

cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleName</key>
	<string>$name</string>
	<key>CFBundleDisplayName</key>
	<string>$name</string>
	<key>CFBundleIdentifier</key>
	<string>org.simple-eiffel.graph-calc</string>
	<key>CFBundleExecutable</key>
	<string>simple_graph_calc</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>$version</string>
	<key>CFBundleVersion</key>
	<string>$version</string>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleLocalizations</key>
	<array>
		<string>en</string>
		<string>he</string>
	</array>
	<key>LSApplicationCategoryType</key>
	<string>public.app-category.education</string>
	<key>LSMinimumSystemVersion</key>
	<string>13.0</string>
	<key>NSHighResolutionCapable</key>
	<true/>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
	<key>NSHumanReadableCopyright</key>
	<string>Simple Eiffel</string>
</dict>
</plist>
PLIST
plutil -lint "$app/Contents/Info.plist" >/dev/null

# Self-contained: the libraries from outside the system (Homebrew's cairo and its own) go
# inside the bundle, so the app runs on a Mac without Homebrew.
sh "$here/scripts/bundle_macos_libraries.sh" "$app" >/dev/null

# Ad-hoc signature: required for arm64 code, and it seals the bundle's contents.
codesign --force --sign - "$app" >/dev/null 2>&1
codesign --verify "$app"

echo "$app"
