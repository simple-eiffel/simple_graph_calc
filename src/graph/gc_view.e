note
	description: "[
		The visible region of the plane, and the mapping between plane and pixels.
		Pixels run right and down; the plane runs right and up.
	]"

class
	GC_VIEW

create
	make, make_standard

feature {NONE} -- Initialization

	make_standard
			-- x from -10 to 10, y from -6 to 6.
		do
			make (-10.0, 10.0, -6.0, 6.0)
		end

	make (a_x_min, a_x_max, a_y_min, a_y_max: REAL_64)
		require
			x_range: a_x_min < a_x_max
			y_range: a_y_min < a_y_max
		do
			x_min := a_x_min
			x_max := a_x_max
			y_min := a_y_min
			y_max := a_y_max
		ensure
			set: x_min = a_x_min and x_max = a_x_max and y_min = a_y_min and y_max = a_y_max
		end

feature -- Access

	x_min, x_max, y_min, y_max: REAL_64

	x_span: REAL_64
		do
			Result := x_max - x_min
		end

	y_span: REAL_64
		do
			Result := y_max - y_min
		end

feature -- Mapping

	pixel_x (a_x: REAL_64; a_width: INTEGER): REAL_64
			-- Horizontal pixel for plane x `a_x' in a surface `a_width' wide.
		require
			positive: a_width > 0
		do
			Result := (a_x - x_min) / x_span * a_width
		end

	pixel_y (a_y: REAL_64; a_height: INTEGER): REAL_64
		require
			positive: a_height > 0
		do
			Result := (y_max - a_y) / y_span * a_height
		end

	plane_x (a_pixel: REAL_64; a_width: INTEGER): REAL_64
			-- Plane x at horizontal pixel `a_pixel'.
		require
			positive: a_width > 0
		do
			Result := x_min + a_pixel / a_width * x_span
		end

feature -- Navigation

	pan (a_dx_fraction, a_dy_fraction: REAL_64)
			-- Move the view by fractions of its size (positive: right and up).
		local
			dx, dy: REAL_64
		do
			dx := a_dx_fraction * x_span
			dy := a_dy_fraction * y_span
			x_min := x_min + dx
			x_max := x_max + dx
			y_min := y_min + dy
			y_max := y_max + dy
		ensure
			same_size: (x_span - old x_span).abs < 1.0e-9 * old x_span.abs.max (1.0)
		end

	pan_pixels (a_dx, a_dy: REAL_64; a_width, a_height: INTEGER)
			-- Drag the plane by `a_dx', `a_dy' pixels (the content follows the pointer).
		require
			sized: a_width > 0 and a_height > 0
		do
			pan (- a_dx / a_width, a_dy / a_height)
		end

	zoom (a_factor: REAL_64)
			-- Scale the view about its centre; `a_factor' < 1 zooms in.
		require
			positive: a_factor > 0.0
		local
			cx, cy, hx, hy: REAL_64
		do
			cx := (x_min + x_max) / 2.0
			cy := (y_min + y_max) / 2.0
			hx := x_span / 2.0 * a_factor
			hy := y_span / 2.0 * a_factor
			if hx > 1.0e-9 and hx < 1.0e9 then
				x_min := cx - hx
				x_max := cx + hx
				y_min := cy - hy
				y_max := cy + hy
			end
		end

	reset
		do
			make_standard
		end

	set_region (a_x_min, a_x_max, a_y_min, a_y_max: REAL_64)
			-- Show exactly this region.
		require
			x_range: a_x_min < a_x_max
			y_range: a_y_min < a_y_max
		do
			make (a_x_min, a_x_max, a_y_min, a_y_max)
		ensure
			set: x_min = a_x_min and x_max = a_x_max and y_min = a_y_min and y_max = a_y_max
		end

feature -- Ticks

	tick_step (a_span: REAL_64): REAL_64
			-- A round step (1, 2 or 5 times a power of ten) giving about eight ticks over `a_span'.
		require
			positive: a_span > 0.0
		local
			l_raw, l_power: REAL_64
		do
			l_raw := a_span / 8.0
			l_power := 10.0 ^ ({DOUBLE_MATH}.log10 (l_raw).floor)
			if l_raw / l_power < 1.5 then
				Result := l_power
			elseif l_raw / l_power < 3.5 then
				Result := 2.0 * l_power
			elseif l_raw / l_power < 7.5 then
				Result := 5.0 * l_power
			else
				Result := 10.0 * l_power
			end
		ensure
			positive: Result > 0.0
		end

invariant
	x_ordered: x_min < x_max
	y_ordered: y_min < y_max

end
