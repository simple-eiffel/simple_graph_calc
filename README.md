# Eiffel Graphing Calculator (simple_graph_calc)

A scientific graphing calculator written in Eiffel on **simple_gui**: one program, unchanged, on all three platforms. It is a native application on Linux (GTK 4) and macOS (AppKit), and on Windows it runs over simple_widgets (simple_gui's Windows backend, the Cairo look). It is the showcase and test bed for simple_gui.

- **Expressions** parsed by a grammar generated with Gobo's geyacc (`grammar/gc_parser.y`): implicit multiplication (`2x`, `3sin(x)`), `^`, `²`, `√`, `·`, `×`, `−`, π and e, and one variable of any name, including Greek (θ, α, λ).
- **Maths** from simple_math (functions, root bisection) and simple_calculus (derivative, integral).
- **Graphs** drawn with simple_cairo on a native canvas: pan with the arrow keys or the mouse, zoom with + and −.
- **Analysis** (f′(x₀), ∫ from a to b, roots) runs on a SCOOP worker, so the window stays responsive.

Status: 0.1. On Linux (GTK 4, WSLg), macOS (AppKit) and Windows (simple_widgets) all 19 tests pass: 7 for the grammar, 12 for a scripted session through simple_gui's test driver that plots, analyses on the worker, zooms, opens the table window, exports a PNG, saves and reopens a session, and switches to dark and to the Hebrew interface. The pictures below come from that session, on each platform.

| | Linux (GTK 4) | macOS (AppKit) | Windows (simple_widgets) |
|---|---|---|---|
| Light, with analysis | ![light, Linux](docs/gallery/linux/gallery_2_analysis.png) | ![light, macOS](docs/gallery/macos/gallery_2_analysis.png) | ![light, Windows](docs/gallery/windows/gallery_2_analysis.png) |
| Dark, two functions | ![dark, Linux](docs/gallery/linux/gallery_4_dark.png) | ![dark, macOS](docs/gallery/macos/gallery_4_dark.png) | ![dark, Windows](docs/gallery/windows/gallery_4_dark.png) |
| Hebrew interface (mirrored) | ![Hebrew, Linux](docs/gallery/linux/gallery_5_hebrew.png) | ![Hebrew, macOS](docs/gallery/macos/gallery_5_hebrew.png) | ![Hebrew, Windows](docs/gallery/windows/gallery_5_hebrew.png) |
| Table of values | ![table, Linux](docs/gallery/linux/gallery_3_table.png) | ![table, macOS](docs/gallery/macos/gallery_3_table.png) | ![table, Windows](docs/gallery/windows/gallery_3_table.png) |

On macOS the menus are in the system menu bar, so they do not appear in the window pictures. The Hebrew interface translates the menus too; the Hebrew wording is machine-written.

On Windows the window keeps the size the program asks for (GTK and AppKit grow a window to fit its content), so the lower part of the analysis panel is cut off in these pictures; the table window opens as a window of its own beside the main one.

## Build it yourself on a Mac

Everything below was checked on 2026-11-08: fresh clones from GitHub, a shell with nothing set but these lines, and plain `ec`. It works on Apple silicon with macOS 15.

**1. Tools, once.** Apple's Command Line Tools (`xcode-select --install`), then [Homebrew](https://brew.sh), then:

```
brew install eiffelstudio cairo pkgconf
```

**2. The source.** The calculator and the 13 libraries it builds on, side by side in one folder:

```
mkdir -p ~/simple_eiffel && cd ~/simple_eiffel
for r in simple_graph_calc simple_gui simple_cairo simple_math simple_mml simple_sorter \
         simple_calculus simple_json simple_datetime simple_decimal simple_zstring \
         simple_reflection simple_encoding simple_factory; do
  git clone https://github.com/simple-eiffel/$r.git
done
```

**3. The environment** (put it in `~/.zprofile` to keep it). EiffelStudio's own copy of Gobo is enough, so nothing else needs downloading:

```
eval "$(/opt/homebrew/bin/brew shellenv)"
export ISE_EIFFEL="$(brew --prefix eiffelstudio)"
export ISE_PLATFORM=macosx-x86-64        # Homebrew's label; the build is native arm64
export ISE_LIBRARY="$ISE_EIFFEL"
export GOBO_LIBRARY="$ISE_EIFFEL/contrib/library/gobo/library"
export PATH="$ISE_EIFFEL/studio/spec/$ISE_PLATFORM/bin:$PATH"
export SIMPLE_EIFFEL=~/simple_eiffel
```

**4. Build, and wrap it as an app:**

```
make -C $SIMPLE_EIFFEL/simple_gui/Clib       # the AppKit backend's object (not in git)
cd $SIMPLE_EIFFEL/simple_graph_calc
ec -batch -config simple_graph_calc.ecf -target simple_graph_calc -finalize -c_compile
sh scripts/make_macos_app.sh EIFGENs/simple_graph_calc/F_code/simple_graph_calc
open "dist/Eiffel Graphing Calculator.app"
```

The first `ec` run takes several minutes. Its `ld: warning: ... libSystem.tbd` lines are harmless. `ec` can exit 0 even when its C step fails, so check that `EIFGENs/simple_graph_calc/F_code/simple_graph_calc` exists before running the script. That `ec` line finalizes without contracts, as an application for people to use should; the test target (`simple_graph_calc_tests`) keeps them.

**What the script makes.** It uses only tools that ship with macOS:
- `Info.plist`, naming the app "Eiffel Graphing Calculator" with bundle id `org.simple-eiffel.graph-calc`, in English and Hebrew;
- the icon, from `packaging/macos/app_icon_1024.png`;
- copies of the libraries the calculator needs from outside the system: Homebrew's cairo and the 15 libraries it pulls in. They go into `Contents/Frameworks`, and the app is pointed at those copies (`scripts/bundle_macos_libraries.sh`).

It then signs everything ad hoc, which Apple silicon requires.

The result is about 8 MB and runs without Homebrew. It is built for the Mac that builds it. Anyone who wants it on their own Mac builds it the same way, from source.

## Regenerating the parser

The generated `src/expression/gc_parser.e` is committed; you only need geyacc if you change the grammar:

```
sh scripts/generate_parser.sh
```

Keep the grammar ASCII (geyacc 22.01 re-encodes UTF-8); write characters as `'%/8730/'`.
