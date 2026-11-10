note
	description: "[
		The analysis worker's math, without a window: roots the graph only touches, the
		corner where f' is undefined, and the cases that must not change.
	]"

class
	GC_ANALYSIS_TESTS

inherit
	GC_TEST_SUPPORT

feature -- Roots

	test_touch_zero_roots_are_found
			-- abs(sin(x)) never changes sign, yet is zero at kπ: all seven in [-10, 10].
		local
			l_roots: ARRAYED_LIST [REAL_64]
			k: INTEGER
		do
			l_roots := analyzer.roots (node ("abs(sin(x))"), -10.0, 10.0)
			assert ("seven roots, got " + l_roots.count.out, l_roots.count = 7)
			from k := -3 until k > 3 loop
				assert ("k = " + k.out + " at " + l_roots [k + 4].out, (l_roots [k + 4] - k * {SIMPLE_MATH}.pi).abs < 1.0e-6)
				k := k + 1
			end
		end

	test_touch_and_crossing_together
			-- (x-1)²(x+2): a touch at 1 and a crossing at -2, in order; x² touches at 0.
		local
			l_roots: ARRAYED_LIST [REAL_64]
		do
			l_roots := analyzer.roots (node ("(x-1)^2*(x+2)"), -10.0, 10.0)
			assert ("two roots, got " + l_roots.count.out, l_roots.count = 2)
			assert ("-2 first", (l_roots [1] + 2.0).abs < 1.0e-6)
			assert ("then 1", (l_roots [2] - 1.0).abs < 1.0e-6)
			l_roots := analyzer.roots (node ("x^2"), -10.0, 10.0)
			assert ("x² has its one root", l_roots.count = 1 and then l_roots [1].abs < 1.0e-6)
		end

	test_near_misses_are_not_roots
			-- x² + 0.01 comes near zero and never reaches it; sin(x) keeps its seven crossings,
			-- none counted twice.
		do
			assert ("x²+0.01 has none", analyzer.roots (node ("x^2+0.01"), -10.0, 10.0).is_empty)
			assert ("sin keeps seven", analyzer.roots (node ("sin(x)"), -10.0, 10.0).count = 7)
		end

feature -- The derivative

	test_corner_has_no_derivative
			-- abs(sin(x)) and abs(x) at 0: the slopes from either side disagree, so f'(0) is
			-- undefined; away from the corner, and for smooth functions, f' is as before.
		do
			assert ("abs(sin(x)) at 0", analyzer.safe_derivative (node ("abs(sin(x))"), 0.0).is_nan)
			assert ("abs(x) at 0", analyzer.safe_derivative (node ("abs(x)"), 0.0).is_nan)
			assert ("shown as undefined", analyzer.short (analyzer.safe_derivative (node ("abs(x)"), 0.0)).same_string ("undefined"))
			assert ("abs(sin(x)) at 1 is cos 1", (analyzer.safe_derivative (node ("abs(sin(x))"), 1.0) - {DOUBLE_MATH}.cosine (1.0)).abs < 1.0e-5)
			assert ("x³ at 0 is 0, smooth", analyzer.safe_derivative (node ("x^3"), 0.0).abs < 1.0e-6)
			assert ("sin(100x) at 0.3 is defined", not analyzer.safe_derivative (node ("sin(100x)"), 0.3).is_nan)
		end

feature {NONE} -- Fixture

	analyzer: GC_ANALYZER
		once
			create Result.make (create {GUI_MAILBOX}.make)
		end

	node (a_text: READABLE_STRING_32): GC_NODE
		local
			l_parser: GC_PARSER
		do
			create l_parser.make
			l_parser.parse_text (a_text)
			check parsed: attached l_parser.last_node as al_node then
				Result := al_node
			end
		end

end
