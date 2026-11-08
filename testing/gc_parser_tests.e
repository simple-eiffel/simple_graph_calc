note
	description: "The expression grammar: values, precedence, implicit multiplication, Unicode, errors."

class
	GC_PARSER_TESTS

inherit
	GC_TEST_SUPPORT

feature -- Tests

	test_precedence
		do
			check_value ("2+3*4", 0.0, 14.0)
			check_value ("(2+3)*4", 0.0, 20.0)
			check_value ("2^3^2", 0.0, 512.0)
			check_value ("-x^2", 3.0, -9.0)
			check_value ("10-4-3", 0.0, 3.0)
			check_value ("8/4/2", 0.0, 1.0)
		end

	test_implicit_multiplication
		do
			check_value ("2x", 3.0, 6.0)
			check_value ("3sin(x)", {SIMPLE_MATH}.pi / 2.0, 3.0)
			check_value ("x(x+1)", 2.0, 6.0)
			check_value ("2x^2", 3.0, 18.0)
			check_value ("2(x+1)", 4.0, 10.0)
		end

	test_unicode_operators_and_greek
		do
			check_value ({STRING_32} "x²", 3.0, 9.0)
			check_value ({STRING_32} "√x", 16.0, 4.0)
			check_value ({STRING_32} "3·θ", 2.0, 6.0)
			check_value ({STRING_32} "4×λ − 1", 2.0, 7.0)
			check_value ({STRING_32} "2π", 0.0, 2.0 * {SIMPLE_MATH}.pi)
			check_value ({STRING_32} "sin(θ)·e^(−θ/4)", 1.0, math.sin (1.0) * math.exp (-0.25))
			check_value ({STRING_32} "sin(θ)e^(−θ/4)", 1.0, math.sin (1.0) * math.exp (-0.25))
		end

	test_variable_is_reported
		local
			p: GC_PARSER
		do
			create p.make
			p.parse_text ({STRING_32} "α^2 + 1")
			assert ("parsed", p.is_parsed)
			assert ("variable", attached p.variable_name as al_v and then al_v.same_string ({STRING_32} "α"))
			p.parse_text ("3 + 4")
			assert ("constant has no variable", p.variable_name = Void)
		end

	test_domain_gives_nan
		do
			check_nan ("ln(-1)", 0.0)
			check_nan ("1/x", 0.0)
			check_nan ("sqrt(x)", -4.0)
			check_nan ("(-8)^0.5", 0.0)
		end

	test_errors_are_reported
		do
			check_error ("2+")
			check_error ("sin(")
			check_error ("x+y")
			check_error ("")
			check_error ("2 $ 3")
		end

	test_two_variables_message
		local
			p: GC_PARSER
		do
			create p.make
			p.parse_text ("x + y")
			assert ("says why", attached p.error_message as al_m and then al_m.has_substring ("two variables"))
		end

feature {NONE} -- Helpers

	check_value (a_text: READABLE_STRING_32; a_x, an_expected: REAL_64)
		local
			p: GC_PARSER
		do
			create p.make
			p.parse_text (a_text)
			if attached p.last_node as al_node then
				assert (a_text.out + " = " + an_expected.out + ", got " + al_node.value (a_x).out, (al_node.value (a_x) - an_expected).abs < 1.0e-9)
			else
				assert (a_text.out + " did not parse: " + (if attached p.error_message as al_m then al_m.out else "?" end), False)
			end
		end

	check_nan (a_text: READABLE_STRING_32; a_x: REAL_64)
		local
			p: GC_PARSER
		do
			create p.make
			p.parse_text (a_text)
			assert (a_text.out + " parses", attached p.last_node)
			if attached p.last_node as al_node then
				assert (a_text.out + " is NaN", al_node.value (a_x).is_nan)
			end
		end

	check_error (a_text: READABLE_STRING_32)
		local
			p: GC_PARSER
		do
			create p.make
			p.parse_text (a_text)
			assert (a_text.out + " rejected", not p.is_parsed and attached p.error_message)
		end

	math: SIMPLE_MATH
		once
			create Result.make
		end

end
