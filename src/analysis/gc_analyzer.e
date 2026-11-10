note
	description: "[
		The analysis worker, on its own SCOOP processor. The GUI hands it a request
		with `set_request' (copied in at once), then calls `analyze' asynchronously; the
		result goes back through the GUI's mailbox, followed by a wake. The worker
		parses the expression itself, so no object is shared with the GUI.

		Result payload (tag Result_tag), one "key=value" per line: request (the
		request's number, so the GUI can drop stale results), then derivative,
		integral, roots (comma-separated), or error.
	]"

class
	GC_ANALYZER

inherit
	GC_FORMAT

create
	make

feature {NONE} -- Initialization

	make (a_mailbox: separate GUI_MAILBOX)
		do
			mailbox := a_mailbox
			create expression.make_empty
		end

feature -- Constants

	Result_tag: INTEGER = 1

feature -- Requests

	set_request (a_number: INTEGER; a_expression: separate READABLE_STRING_32; a_x0, a_a, a_b, a_low, a_high: REAL_64)
			-- Copy request `a_number' in (called synchronously by the GUI).
		do
			request_number := a_number
			create expression.make_from_separate (a_expression)
			x0 := a_x0
			a := a_a
			b := a_b
			low := a_low
			high := a_high
		end

	analyze
			-- Work out the request and post the result (called asynchronously).
		local
			l_parser: GC_PARSER
			l_out: STRING_32
		do
			create l_parser.make
			l_parser.parse_text (expression)
			create l_out.make (80)
			l_out.append ({STRING_32} "request=" + request_number.out + {STRING_32} "%N")
			if attached l_parser.last_node as al_node then
				l_out.append ({STRING_32} "derivative=" + short (safe_derivative (al_node, x0)) + {STRING_32} "%N")
				if a < b then
					l_out.append ({STRING_32} "integral=" + short (safe_integral (al_node, a, b)) + {STRING_32} "%N")
				else
					l_out.append ({STRING_32} "integral=undefined%N")
				end
				l_out.append ({STRING_32} "roots=" + roots_text (al_node, low, high) + {STRING_32} "%N")
			elseif attached l_parser.error_message as al_message then
				l_out.append ({STRING_32} "error=" + al_message + {STRING_32} "%N")
			end
			post (mailbox, l_out)
			(create {GUI_WAKE}).wake
		end

feature -- Access (for tests)

	expression: STRING_32
	request_number: INTEGER
	x0, a, b, low, high: REAL_64

feature -- Calculations

	safe_derivative (a_node: GC_NODE; a_x: REAL_64): REAL_64
			-- f'(a_x) by simple_calculus, or NaN ("undefined") where f is undefined nearby or
			-- where f has a corner: the slopes from the left and from the right disagree.
		local
			l_retried: BOOLEAN
		do
			if l_retried or a_node.value (a_x).is_nan or a_node.value (a_x - 1.0e-4).is_nan or a_node.value (a_x + 1.0e-4).is_nan
				or else is_corner (a_node, a_x)
			then
				Result := {REAL_64}.nan
			else
				Result := calculus.derivative (agent a_node.value, a_x)
			end
		rescue
			l_retried := True
			retry
		end

	is_corner (a_node: GC_NODE; a_x: REAL_64): BOOLEAN
			-- Do the one-sided slopes at `a_x' disagree (abs(sin(x)) at 0: -1 and 1)? With a
			-- step of a millionth, a smooth function's two slopes differ by about the step times
			-- f'', far inside the tolerance: a thousandth of the larger slope, or of 1.
		local
			h, f0, l_left, l_right: REAL_64
		do
			h := 1.0e-6 * a_x.abs.max (1.0)
			f0 := a_node.value (a_x)
			l_left := (f0 - a_node.value (a_x - h)) / h
			l_right := (a_node.value (a_x + h) - f0) / h
			Result := not l_left.is_nan and not l_right.is_nan
				and then (l_left - l_right).abs > 1.0e-3 * l_left.abs.max (l_right.abs).max (1.0)
		end

	safe_integral (a_node: GC_NODE; a_a, a_b: REAL_64): REAL_64
			-- The integral from `a_a' to `a_b' by simple_calculus, or NaN.
		require
			ordered: a_a < a_b
		local
			l_retried: BOOLEAN
		do
			if l_retried then
				Result := {REAL_64}.nan
			else
				Result := calculus.integrate (agent a_node.value, a_a, a_b)
			end
		rescue
			l_retried := True
			retry
		end

	roots (a_node: GC_NODE; a_low, a_high: REAL_64): ARRAYED_LIST [REAL_64]
			-- Roots in [a_low, a_high], in order: sign changes over 400 steps, refined by
			-- simple_math's bisection, keeping only true zeros (not poles such as tan's); and
			-- zeros the graph only touches (abs(sin(x)) at kπ, x² at 0), found where |f| has a
			-- local minimum between samples of one sign and refined by a golden-section search.
		require
			ordered: a_low < a_high
		local
			i, n: INTEGER
			l_xa, x1, x2, l_ya, y1, y2, r, l_step: REAL_64
			l_touches: ARRAYED_LIST [REAL_64]
		do
			create Result.make (4)
			create l_touches.make (2)
			n := 400
			l_step := (a_high - a_low) / n
			from
				i := 0
				x1 := a_low
				y1 := a_node.value (x1)
			until
				i >= n or Result.count >= 12
			loop
				x2 := a_low + (i + 1) * l_step
				y2 := a_node.value (x2)
				if not y1.is_nan and not y2.is_nan then
					if y1 = 0.0 then
						add_root (Result, x1)
					elseif y1 * y2 < 0.0 then
						r := math.bisection (agent a_node.value, x1, x2, 1.0e-10, 200)
						if r.abs < 1.0e-9 * (a_high - a_low).max (1.0) then
								-- Floating-point noise around zero differs by platform (-9.3e-11 on macOS): snap it.
							r := 0.0
						end
						if a_node.value (r).abs < 1.0e-6 then
							add_root (Result, r)
						end
					end
				end
				if i >= 1 and then not l_ya.is_nan and not y1.is_nan and not y2.is_nan and then l_ya * y1 > 0.0 and then y1 * y2 > 0.0
					and then y1.abs <= l_ya.abs and then y1.abs <= y2.abs
				then
					r := touch_zero (a_node, l_xa, x2)
					if not r.is_nan then
						if r.abs < 1.0e-9 * (a_high - a_low).max (1.0) then
							r := 0.0
						end
						l_touches.extend (r)
					end
				end
				l_xa := x1
				l_ya := y1
				x1 := x2
				y1 := y2
				i := i + 1
			end
			if not l_touches.is_empty then
				Result := merged (Result, l_touches, 1.0e-7 * (a_high - a_low).max (1.0))
			end
		end

	touch_zero (a_node: GC_NODE; a_low, a_high: REAL_64): REAL_64
			-- Where |f| is least in [a_low, a_high] (golden-section search), if f is zero there
			-- to within 1e-9; else NaN.
		local
			l_a, l_b, c, d, fc, fd: REAL_64
			k: INTEGER
		do
			l_a := a_low
			l_b := a_high
			c := l_b - Golden * (l_b - l_a)
			d := l_a + Golden * (l_b - l_a)
			fc := a_node.value (c).abs
			fd := a_node.value (d).abs
			from k := 1 until k > 120 or (l_b - l_a) < 1.0e-13 * (l_a.abs + l_b.abs).max (1.0) loop
				if fc <= fd then
					l_b := d
					d := c
					fd := fc
					c := l_b - Golden * (l_b - l_a)
					fc := a_node.value (c).abs
				else
					l_a := c
					c := d
					fc := fd
					d := l_a + Golden * (l_b - l_a)
					fd := a_node.value (d).abs
				end
				k := k + 1
			end
			Result := (l_a + l_b) / 2.0
			if a_node.value (Result).is_nan or else a_node.value (Result).abs > 1.0e-9 then
				Result := {REAL_64}.nan
			end
		end

	Golden: REAL_64 = 0.6180339887498949
			-- 1 / φ.

	merged (a_crossings, a_touches: ARRAYED_LIST [REAL_64]; a_near: REAL_64): ARRAYED_LIST [REAL_64]
			-- Both lists in one, in order, a root within `a_near' of another kept once.
			-- (Both come from the scan in ascending order.)
		local
			i, j: INTEGER
			l_next: REAL_64
		do
			create Result.make (a_crossings.count + a_touches.count)
			from i := 1; j := 1 until i > a_crossings.count and j > a_touches.count loop
				if j > a_touches.count or else (i <= a_crossings.count and then a_crossings [i] <= a_touches [j]) then
					l_next := a_crossings [i]
					i := i + 1
				else
					l_next := a_touches [j]
					j := j + 1
				end
				if Result.is_empty or else (l_next - Result.last).abs > a_near then
					Result.extend (l_next)
				end
			end
		ensure
			ascending: across 2 |..| Result.count as ic all Result [ic - 1] < Result [ic] end
		end

	roots_text (a_node: GC_NODE; a_low, a_high: REAL_64): STRING_32
		do
			create Result.make_empty
			if a_low < a_high then
				across roots (a_node, a_low, a_high) as ic loop
					if not Result.is_empty then
						Result.append ({STRING_32} ", ")
					end
					Result.append (short (ic))
				end
			end
			if Result.is_empty then
				Result := {STRING_32} "none"
			end
		end

feature {NONE} -- Implementation

	mailbox: separate GUI_MAILBOX

	post (a_mailbox: separate GUI_MAILBOX; a_text: STRING_32)
		do
			a_mailbox.put (Result_tag, a_text)
		end

	add_root (a_list: ARRAYED_LIST [REAL_64]; a_root: REAL_64)
			-- Add `a_root' unless it repeats the last one.
		do
			if a_list.is_empty or else (a_list.last - a_root).abs > 1.0e-7 then
				a_list.extend (a_root)
			end
		end

	calculus: SIMPLE_CALCULUS
		once
			create Result
		end

	math: SIMPLE_MATH
		once
			create Result.make
		end

end
