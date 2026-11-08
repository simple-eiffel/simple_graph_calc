note
	description: "[
		The scripted session, the same on every platform: type a function, plot it,
		let the worker analyse it, zoom, open the table window, switch to dark and to
		the Hebrew interface, and snapshot each step (gallery_*.png).
	]"

class
	GC_GALLERY_TESTS

inherit
	GC_TEST_SUPPORT

create
	make

feature {NONE} -- Initialization

	make (a_app: GUI_APPLICATION)
		do
			app := a_app
			create driver
			create main.make (a_app)
			main.show
			settle
		end

feature -- Tests

	test_plot_from_the_keypad
			-- Build sin(θ)·e^(−θ/4) partly with keypad buttons, then press Plot.
		do
			driver.type_text (main.expression_field, "")
			driver.perform_click (key ("sin"))
			driver.perform_click (key ("θ"))
			driver.type_text (main.expression_field, main.expression_field.text + ")·e^(−θ/4)")
			assert ("typed", main.expression_field.text.same_string ({STRING_32} "sin(θ)·e^(−θ/4)"))
			driver.perform_click (main.plot_button)
			assert ("one plot", main.plots.count = 1 and main.function_list.count = 1)
			assert ("selected", main.function_list.selected_index = 1)
			assert ("variable theta", main.plots.first.variable.same_string ({STRING_32} "θ"))
			snapshot ("gallery_1_plot")
		end

	test_worker_analysis_arrives
			-- f'(0) = 1; the integral from 0 to pi = 16(1 + e^(-pi/4))/17; roots include pi.
		local
			i: INTEGER
			l_expected: REAL_64
		do
			from
				i := 1
			until
				main.analyses_received >= 1 or i > 60
			loop
				app.process_events (100)
				i := i + 1
			end
			assert ("result arrived", main.analyses_received >= 1)
			assert ("derivative 1, got " + main.derivative_value.text.out, main.derivative_value.text.same_string ("1"))
			l_expected := 16.0 * (1.0 + {DOUBLE_MATH}.exp (- {SIMPLE_MATH}.pi / 4.0)) / 17.0
			assert ("integral, got " + main.integral_value.text.out,
				main.integral_value.text.is_real_64 and then (main.integral_value.text.to_real_64 - l_expected).abs < 1.0e-4)
			assert ("pi is a root, got " + main.roots_value.text.out, main.roots_value.text.has_substring ("3.141593"))
			assert ("root markers", main.roots.count >= 5)
			settle
			snapshot ("gallery_2_analysis")
		end

	test_zoom_changes_the_view
		local
			l_span: REAL_64
		do
			l_span := main.view.x_span
			driver.perform_click (main.zoom_in_button)
			assert ("zoomed in", main.view.x_span < l_span)
			driver.perform_click (main.reset_button)
			assert ("reset", (main.view.x_span - 20.0).abs < 1.0e-9)
		end

	test_second_plot_and_table_window
		do
			driver.type_text (main.expression_field, {STRING_32} "x²/4 − 2")
			driver.perform_click (main.plot_button)
			assert ("two plots", main.plots.count = 2)
			driver.invoke_menu (main.table_item_id)
			settle
			assert ("table open", attached main.table as al_t and then al_t.rows.count = {GC_TABLE_WINDOW}.Row_count)
			if attached main.table as al_t then
				driver.pump_until_idle (200)
				assert ("table png", driver.snapshot (al_t.window, create {PATH}.make_from_string ("gallery_3_table.png")))
			end
			snapshot ("gallery_3_two_plots")
		end

	test_dark_appearance
		do
			driver.set_dark (True)
			settle
			assert ("dark", app.is_dark)
			snapshot ("gallery_4_dark")
			driver.set_dark (False)
			settle
		end

	test_hebrew_interface_mirrors
		do
			driver.invoke_menu (main.hebrew_item_id)
			settle
			assert ("hebrew text", main.plot_button.text.same_string ({STRING_32} "שרטט"))
			assert ("mirrored", main.root.base_direction = main.root.Direction_right_to_left)
			assert ("expression stays left to right", main.expression_field.base_direction = main.root.Direction_left_to_right)
			assert ("numbers stay left to right", main.roots_value.base_direction = main.root.Direction_left_to_right)
			snapshot ("gallery_5_hebrew")
			driver.invoke_menu (main.hebrew_item_id)
			settle
			assert ("english again", main.plot_button.text.same_string ("Plot"))
		end

	test_spoken_labels_reach_the_assistive_tree
		local
			l_tree: STRING_32
		do
			l_tree := driver.describe_accessibility (main.window)
			assert ("square root spoken", l_tree.has_substring ("button: square root"))
			assert ("theta spoken", l_tree.has_substring ("button: theta"))
			assert ("field labelled", l_tree.has_substring ("text-box: Function"))
		end

	test_export_png
		do
			assert ("exported", main.export_png (create {PATH}.make_from_string ("gallery_export.png")))
		end

	test_bad_expression_is_reported
		local
			l_count: INTEGER
		do
			l_count := main.plots.count
			driver.type_text (main.expression_field, "2 +")
			driver.perform_click (main.plot_button)
			assert ("not added", main.plots.count = l_count)
			assert ("message", main.status_label.text.has_substring ("unexpected"))
		end

feature {NONE} -- Helpers

	app: GUI_APPLICATION
	driver: GUI_TEST_DRIVER
	main: GC_MAIN_WINDOW

	key (a_face: STRING_32): GUI_BUTTON
			-- The keypad button showing `a_face'.
		do
			Result := main.keypad_buttons.first
			across main.keypad_buttons as ic loop
				if ic.text.same_string (a_face) then
					Result := ic
				end
			end
		end

	snapshot (a_name: STRING)
		do
			settle
			assert (a_name + ".png", driver.snapshot (main.window, create {PATH}.make_from_string (a_name + ".png")))
		end

	settle
		local
			i: INTEGER
		do
			from i := 1 until i > 10 loop
				app.process_events (30)
				i := i + 1
			end
		end

end
