# Eiffel Graphing Calculator (simple_graph_calc)

A scientific graphing calculator written in Eiffel on **simple_gui**, so it is a native application on each platform: GTK 4 on Linux, AppKit on macOS (Windows over simple_widgets later). It is the showcase and test bed for simple_gui.

- **Expressions** parsed by a grammar generated with Gobo's geyacc (`grammar/gc_parser.y`): implicit multiplication (`2x`, `3sin(x)`), `^`, `²`, `√`, `·`, `×`, `−`, π and e, and one variable of any name, including Greek (θ, α, λ).
- **Maths** from simple_math (functions, root bisection) and simple_calculus (derivative, integral).
- **Graphs** drawn with simple_cairo on a native canvas: pan with the arrow keys or the mouse, zoom with + and −.
- **Analysis** (f′(x₀), ∫ from a to b, roots) runs on a SCOOP worker, so the window stays responsive.

Status: 0.1. On Linux (GTK 4, WSLg) all 16 tests pass: 7 for the grammar, 9 for a scripted session through simple_gui's test driver that plots, analyses on the worker, zooms, opens the table window, and switches to dark and to the Hebrew interface. macOS: in progress.

| Light, with analysis | Dark, two functions | Hebrew interface (mirrored) |
|---|---|---|
| ![light](docs/gallery/linux/gallery_2_analysis.png) | ![dark](docs/gallery/linux/gallery_4_dark.png) | ![hebrew](docs/gallery/linux/gallery_5_hebrew.png) |

Menus stay in English in 0.1 (simple_gui cannot yet relabel menu items). The Hebrew wording is machine-written.

## Regenerating the parser

The generated `src/expression/gc_parser.e` is committed; you only need geyacc if you change the grammar:

```
sh scripts/generate_parser.sh
```

Keep the grammar ASCII (geyacc 22.01 re-encodes UTF-8); write characters as `'%/8730/'`.
