# Eiffel Graphing Calculator (simple_graph_calc)

A scientific graphing calculator written in Eiffel on **simple_gui**: one program, unchanged, on all three platforms. It is a native application on Linux (GTK 4) and macOS (AppKit), and on Windows it runs over simple_widgets (simple_gui's Windows backend, the Cairo look). It is the showcase and test bed for simple_gui.

- **Expressions** parsed by a grammar generated with Gobo's geyacc (`grammar/gc_parser.y`): implicit multiplication (`2x`, `3sin(x)`), `^`, `²`, `√`, `·`, `×`, `−`, π and e, and one variable of any name, including Greek (θ, α, λ).
- **Maths** from simple_math (functions, root bisection) and simple_calculus (derivative, integral).
- **Graphs** drawn with simple_cairo on a native canvas: pan with the arrow keys or the mouse, zoom with + and −.
- **Analysis** (f′(x₀), ∫ from a to b, roots) runs on a SCOOP worker, so the window stays responsive.
  - Roots include zeros the graph only touches without crossing, such as abs(sin(x)) at kπ and x² at 0.
  - At a corner, where the slopes from the left and the right disagree (abs(sin(x)) at 0), f′ is reported as undefined, not as 0.

Status: 0.1. On Linux (GTK 4, WSLg), macOS (AppKit) and Windows (simple_widgets) all 19 tests pass: 7 for the grammar, 12 for a scripted session through simple_gui's test driver that plots, analyses on the worker, zooms, opens the table window, exports a PNG, saves and reopens a session, and switches to dark and to the Hebrew interface. The pictures below come from that session, on each platform.

| | Linux (GTK 4) | macOS (AppKit) | Windows (simple_widgets) |
|---|---|---|---|
| Light, with analysis | ![light, Linux](docs/gallery/linux/gallery_2_analysis.png) | ![light, macOS](docs/gallery/macos/gallery_2_analysis.png) | ![light, Windows](docs/gallery/windows/gallery_2_analysis.png) |
| Dark, two functions | ![dark, Linux](docs/gallery/linux/gallery_4_dark.png) | ![dark, macOS](docs/gallery/macos/gallery_4_dark.png) | ![dark, Windows](docs/gallery/windows/gallery_4_dark.png) |
| Hebrew interface (mirrored) | ![Hebrew, Linux](docs/gallery/linux/gallery_5_hebrew.png) | ![Hebrew, macOS](docs/gallery/macos/gallery_5_hebrew.png) | ![Hebrew, Windows](docs/gallery/windows/gallery_5_hebrew.png) |
| Table of values | ![table, Linux](docs/gallery/linux/gallery_3_table.png) | ![table, macOS](docs/gallery/macos/gallery_3_table.png) | ![table, Windows](docs/gallery/windows/gallery_3_table.png) |

On macOS the menus are in the system menu bar, so they do not appear in the window pictures. The Hebrew interface translates the menus too; the Hebrew wording is machine-written.

On Windows, as on the others, the window opens large enough for its content; the table window opens as a window of its own beside the main one. The Windows pictures were taken at 150% scaling, where the calculator's content is taller than the screen, so its window stops at the screen's height and the zoom buttons sit just below it.

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

## Build it yourself on Windows

**1. Tools, once.** [EiffelStudio 25.02](https://www.eiffel.org/downloads) and Visual Studio's C++ build tools (EiffelStudio compiles its generated C with them).

**2. The source.** The calculator and the libraries it builds on, side by side in one folder. On Windows the GUI runs over simple_widgets, which brings in more libraries than on the Mac:

```
mkdir simple_eiffel && cd simple_eiffel
for r in simple_graph_calc simple_gui simple_cairo simple_mml simple_widgets simple_shaping \
         simple_datetime simple_document simple_markdown simple_shell simple_audio simple_file \
         simple_encoding simple_speech simple_ai_client simple_logger simple_json simple_decimal \
         simple_zstring simple_reflection simple_factory simple_process simple_sql simple_sorter \
         eiffel_sqlite_2025 simple_uuid simple_ffmpeg simple_onnx simple_vision simple_regex \
         simple_math simple_calculus; do
  git clone https://github.com/simple-eiffel/$r.git
done
```

**3. Cairo.** simple_cairo links `simple_cairo\lib\cairo.lib` and the program loads `cairo.dll` at run time. Neither file is in git: put a 64-bit Cairo build's import library at `simple_cairo\lib\cairo.lib` and its `cairo.dll` where step 5 says (see simple_cairo's README).

**4. The environment** (Git Bash shown; set the same variables in System Properties to keep them). EiffelStudio's own copy of Gobo is enough:

```
export ISE_EIFFEL="/c/Program Files/Eiffel Software/EiffelStudio 25.02 Standard"
export ISE_PLATFORM=win64
export ISE_LIBRARY="$ISE_EIFFEL"
export GOBO_LIBRARY="$ISE_EIFFEL/contrib/library/gobo/library"
export PATH="$ISE_EIFFEL/studio/spec/$ISE_PLATFORM/bin:$PATH"
export SIMPLE_EIFFEL=$PWD
```

**5. Build, and put it in `bin\windows`:**

```
cd simple_graph_calc
ec -batch -config simple_graph_calc.ecf -target simple_graph_calc -finalize -c_compile
mkdir -p bin/windows
cp EIFGENs/simple_graph_calc/F_code/simple_graph_calc.exe bin/windows/
cp ../simple_cairo/cairo.dll bin/windows/
```

That `ec` line finalizes without contracts, as an application for people to use should; the test target (`simple_graph_calc_tests`) keeps them. `ec` can exit 0 even when its C step fails, so check that the executable exists before copying. (On the maintainers' machine, `ec.sh release` does the same and also leaves a `simple_graph_calc_dbc.exe` with contracts.)

Then double-click `bin\windows\simple_graph_calc.exe`. At run time it needs only `cairo.dll` beside it; everything else it loads ships with Windows, and there is no Visual C++ runtime to install. `bin\` is not committed (it is in `.gitignore`).

The Linux build sits in `bin/linux`: run it from WSL or a Linux desktop with `./bin/linux/simple_graph_calc`. It needs GTK 4 and Cairo installed.

The shortcuts use Ctrl (Ctrl+O, S, E, Q; Ctrl+R resets the view and Ctrl+T opens the table), the menu bar sits inside the window, and light and dark follow the Windows setting.

The window opens large enough for its content, as on Linux and macOS, but never taller than the screen: where the content is taller than the screen (at 150% scaling on the display these pictures came from), the zoom buttons sit below the bottom edge.

What has been checked, 2026-11-08: the build on the maintainers' machine, and the program running from a folder holding only the executable and `cairo.dll` with nothing on PATH. Unlike the Mac steps, these steps have not yet been run from fresh clones; the clone list comes from the ECFs.

**Not yet checked by hand on Windows.** These are expected to work, from the code and from the shared tests, but nobody has tried them yet by hand:
- the Ctrl shortcuts listed above (the menus declare them as "primary" shortcuts, and primary is Ctrl on Windows);
- the Edit menu (Undo, Redo, Cut, Copy, Paste, Select All) in the text fields;
- switching between light and dark while the calculator is open (it follows the Windows setting at launch, and the shared test `system_colors_follow_the_appearance` passes);
- PNG export at 125 % and 150 % display scaling (checked at 100 % only);
- redrawing the graph while a window edge is being dragged.

## Regenerating the parser

The generated `src/expression/gc_parser.e` is committed; you only need geyacc if you change the grammar:

```
sh scripts/generate_parser.sh
```

Keep the grammar ASCII (geyacc 22.01 re-encodes UTF-8); write characters as `'%/8730/'`.
