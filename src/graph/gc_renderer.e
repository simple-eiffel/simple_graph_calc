note
	description: "[
		Draws the graph into a Cairo image at device scale: background, grid, axes,
		tick labels, each plot's curve (with gaps where it is undefined or jumps off
		the scale), and the roots found by the analysis.
	]"

class
	GC_RENDERER

inherit
	GC_FORMAT

feature -- Drawing

	render (a_surface: CAIRO_SURFACE; a_view: GC_VIEW; a_plots: LIST [GC_PLOT]; a_roots: LIST [REAL_64]; a_dark: BOOLEAN; a_scale: INTEGER)
			-- Draw everything onto `a_surface', whose pixels are `a_scale' times logical pixels.
		require
			valid: a_surface.is_valid
			sized: a_surface.width > 0 and a_surface.height > 0
			scale: a_scale >= 1
		local
			cr: CAIRO_CONTEXT
			w, h: INTEGER
		do
			w := a_surface.width
			h := a_surface.height
			create cr.make (a_surface)
			cr.set_color_hex (if a_dark then Dark_background else Light_background end).paint.do_nothing
			draw_grid (cr, a_view, w, h, a_dark, a_scale)
			across a_plots as ic loop
				draw_curve (cr, a_view, ic, w, h, a_scale)
			end
			across a_roots as ic loop
				cr.set_color_hex (if a_dark then 0xFFFFFF else 0x000000 end)
					.arc (a_view.pixel_x (ic, w), a_view.pixel_y (0.0, h), 4.0 * a_scale, 0.0, 2.0 * {SIMPLE_MATH}.pi)
					.fill.do_nothing
			end
			cr.destroy
			a_surface.flush.do_nothing
		end

feature -- Colors

	Light_background: NATURAL_32 = 0xFFFFFF
	Dark_background: NATURAL_32 = 0x1E1E1E

	Palette: ARRAY [NATURAL_32]
			-- Colors for successive plots, readable on light and dark backgrounds.
		once
			Result := <<0x2F7FD8, 0xE8743B, 0x2CA02C, 0xD62728, 0x9467BD, 0x17BECF>>
		end

feature {NONE} -- Implementation

	draw_grid (cr: CAIRO_CONTEXT; v: GC_VIEW; w, h: INTEGER; a_dark: BOOLEAN; s: INTEGER)
		local
			l_step, x, y, px, py, l_axis_x, l_axis_y: REAL_64
			l_label: STRING_32
		do
			cr.set_line_width (1.0 * s).do_nothing
			cr.select_font ("Sans", 0, 0).set_font_size (11.0 * s).do_nothing
				-- Vertical grid lines and x labels.
			l_step := v.tick_step (v.x_span)
			l_axis_y := v.pixel_y (0.0, h).max (0.0).min (h - 14.0 * s)
			from
				x := (v.x_min / l_step).ceiling_real_64 * l_step
			until
				x > v.x_max
			loop
				px := v.pixel_x (x, w).rounded + 0.5
				cr.set_color_hex (if a_dark then 0x333333 else 0xE6E6E6 end).move_to (px, 0.0).line_to (px, h).stroke.do_nothing
				if x.abs > l_step / 2.0 then
					l_label := short (x)
					cr.set_color_hex (if a_dark then 0xAAAAAA else 0x555555 end).move_to (px + 3.0 * s, l_axis_y + 12.0 * s).show_text (l_label).do_nothing
				end
				x := x + l_step
			end
				-- Horizontal grid lines and y labels.
			l_step := v.tick_step (v.y_span)
			l_axis_x := v.pixel_x (0.0, w).max (0.0).min (w - 40.0 * s)
			from
				y := (v.y_min / l_step).ceiling_real_64 * l_step
			until
				y > v.y_max
			loop
				py := v.pixel_y (y, h).rounded + 0.5
				cr.set_color_hex (if a_dark then 0x333333 else 0xE6E6E6 end).move_to (0.0, py).line_to (w, py).stroke.do_nothing
				if y.abs > l_step / 2.0 then
					l_label := short (y)
					cr.set_color_hex (if a_dark then 0xAAAAAA else 0x555555 end).move_to (l_axis_x + 4.0 * s, py - 3.0 * s).show_text (l_label).do_nothing
				end
				y := y + l_step
			end
				-- Axes.
			cr.set_line_width (1.5 * s).set_color_hex (if a_dark then 0xBBBBBB else 0x444444 end).do_nothing
			if v.x_min < 0.0 and v.x_max > 0.0 then
				px := v.pixel_x (0.0, w)
				cr.move_to (px, 0.0).line_to (px, h).stroke.do_nothing
			end
			if v.y_min < 0.0 and v.y_max > 0.0 then
				py := v.pixel_y (0.0, h)
				cr.move_to (0.0, py).line_to (w, py).stroke.do_nothing
			end
		end

	draw_curve (cr: CAIRO_CONTEXT; v: GC_VIEW; p: GC_PLOT; w, h: INTEGER; s: INTEGER)
			-- Sample once per pixel column; lift the pen at NaN and at jumps larger than the view.
		local
			i: INTEGER
			x, y, py, l_last_py: REAL_64
			l_pen_down: BOOLEAN
		do
			cr.set_line_width (2.0 * s).set_color_hex (p.color).do_nothing
			from
				i := 0
			until
				i > w
			loop
				x := v.plane_x (i, w)
				y := p.value (x)
				if y.is_nan or y.abs > 1.0e12 then
					l_pen_down := False
				else
					py := v.pixel_y (y, h)
					if l_pen_down and (py - l_last_py).abs > h * 1.5 then
						l_pen_down := False
					end
					py := py.max (-h).min (2.0 * h)
					if l_pen_down then
						cr.line_to (i, py).do_nothing
					else
						cr.move_to (i, py).do_nothing
						l_pen_down := True
					end
					l_last_py := py
				end
				i := i + 1
			end
			cr.stroke.do_nothing
		end

end
