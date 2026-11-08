note
	description: "simple_graph_calc test runner (F_code -keep, all assertions live)."

class
	TEST_APP

create
	make

feature {NONE} -- Initialization

	make
		local
			p: GC_PARSER_TESTS
		do
			print ("simple_graph_calc tests%N%N=== EXPRESSION GRAMMAR (geyacc) ===%N")
			create p
			run_test (agent p.test_precedence, "precedence")
			run_test (agent p.test_implicit_multiplication, "implicit_multiplication")
			run_test (agent p.test_unicode_operators_and_greek, "unicode_operators_and_greek")
			run_test (agent p.test_variable_is_reported, "variable_is_reported")
			run_test (agent p.test_domain_gives_nan, "domain_gives_nan")
			run_test (agent p.test_errors_are_reported, "errors_are_reported")
			run_test (agent p.test_two_variables_message, "two_variables_message")
			print ("%N=== Results: " + passed.out + " passed, " + failed.out + " failed ===%N")
			if failed = 0 and passed > 0 then
				print ("ALL TESTS PASSED%N")
			end
		end

	run_test (a_test: PROCEDURE; a_name: STRING)
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				a_test.call (Void)
				print ("  PASS: " + a_name + "%N")
				passed := passed + 1
			end
		rescue
			print ("  FAIL: " + a_name + "%N")
			if attached (create {EXCEPTION_MANAGER}).last_exception as al_e then
				if attached al_e.description as al_why then
					print ("        why: " + {UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (al_why) + "%N")
				end
			end
			failed := failed + 1
			l_retried := True
			retry
		end

	passed: INTEGER

	failed: INTEGER

end
