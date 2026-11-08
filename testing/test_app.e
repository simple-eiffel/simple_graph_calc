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
			g: GC_GALLERY_TESTS
			l_app: GUI_APPLICATION
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
			print ("%N=== THE WINDOW (scripted gallery) ===%N")
			create l_app.make ("Eiffel Graphing Calculator tests", "org.simple-eiffel.graph-calc-tests")
			if l_app.is_available then
				create g.make (l_app)
				run_test (agent g.test_plot_from_the_keypad, "plot_from_the_keypad")
				run_test (agent g.test_worker_analysis_arrives, "worker_analysis_arrives")
				run_test (agent g.test_zoom_changes_the_view, "zoom_changes_the_view")
				run_test (agent g.test_second_plot_and_table_window, "second_plot_and_table_window")
				run_test (agent g.test_dark_appearance, "dark_appearance")
				run_test (agent g.test_hebrew_interface_mirrors, "hebrew_interface_mirrors")
				run_test (agent g.test_spoken_labels_reach_the_assistive_tree, "spoken_labels_reach_the_assistive_tree")
				run_test (agent g.test_export_png, "export_png")
				run_test (agent g.test_bad_expression_is_reported, "bad_expression_is_reported")
			else
				print ("  SKIP: no display%N")
			end
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
