note
	description: "[
		The calculator's main window, built only from simple_gui: an expression field
		with a keypad (each symbol button has a spoken label), the list of plotted
		functions, the analysis panel (worked out on a SCOOP worker), and the graph
		canvas (simple_cairo). Pan with the arrow keys or by dragging; zoom with + and -.
	]"

class
	GC_MAIN_WINDOW

inherit
	GC_FORMAT

create
	make

feature {NONE} -- Initialization

	make (a_app: GUI_APPLICATION)
		require
			available: a_app.is_available
		do
			app := a_app
			create texts.make
			create view.make_standard
			create renderer
			create plots.make (4)
			create roots.make (8)
			create analyzer.make (a_app.mailbox)
			create window.make (texts.title, 1100, 700)
			build_window
			build_menus
			wire_events
			app.message_actions.extend (agent on_message)
			app.appearance_changed_actions.extend (agent (d: BOOLEAN) do render end)
			window.close_requested_actions.extend (agent app.quit)
			apply_texts
		ensure
			no_plots: plots.is_empty
		end

feature -- Access (the test driver and the gallery reach these)

	app: GUI_APPLICATION
	window: GUI_WINDOW
	texts: GC_TEXTS
	view: GC_VIEW
	plots: ARRAYED_LIST [GC_PLOT]
	roots: ARRAYED_LIST [REAL_64]

	root: GUI_STACK
	expression_field: GUI_TEXT_FIELD
	plot_button, clear_button, analyze_button: GUI_BUTTON
	zoom_in_button, zoom_out_button, reset_button: GUI_BUTTON
	keypad_buttons: ARRAYED_LIST [GUI_BUTTON]
	function_list: GUI_LIST
	x0_field, lower_field, upper_field: GUI_TEXT_FIELD
	derivative_value, integral_value, roots_value, status_label: GUI_LABEL
	canvas: GUI_CANVAS
	table: detachable GC_TABLE_WINDOW

	table_item_id, hebrew_item_id, export_item_id: INTEGER
			-- Menu item ids (for tests).

	menu_titles: ARRAYED_LIST [TUPLE [menu: GUI_MENU; key: STRING]]
			-- Top-level menus by text key.

	menu_items: ARRAYED_LIST [TUPLE [menu: GUI_MENU; id: INTEGER; key: STRING]]
			-- Menu items by text key.

	shown_menu_item (a_key: STRING): STRING_32
			-- The words the toolkit shows now on the item called `a_key' (tests).
		do
			create Result.make_empty
			across menu_items as ic loop
				if ic.key.same_string (a_key) then
					Result := ic.menu.item_text (ic.id)
				end
			end
		end

	shown_menu_title (a_key: STRING): STRING_32
			-- The words the toolkit shows now on the menu called `a_key' (tests).
		do
			create Result.make_empty
			across menu_titles as ic loop
				if ic.key.same_string (a_key) then
					Result := ic.menu.shown_title
				end
			end
		end

	analyses_received: INTEGER
			-- Current analysis results that came back from the worker (stale ones are dropped).

	requests_sent: INTEGER
			-- Analysis requests handed to the worker; each result names the one it answers.

	last_image: detachable CAIRO_SURFACE
			-- The image on the canvas now.

feature -- Commands

	show
		do
			window.show
		end

	plot_expression
			-- Parse the field and add it to the graph.
		local
			l_parser: GC_PARSER
			l_plot: GC_PLOT
		do
			create l_parser.make
			l_parser.parse_text (expression_field.text)
			if attached l_parser.last_node as al_node then
				create l_plot.make (expression_field.text, al_node, l_parser.variable_name,
					renderer.Palette [(plots.count \\ renderer.Palette.count) + 1])
				plots.extend (l_plot)
				function_list.extend (l_plot.label)
				function_list.select_row (function_list.count)
				render
				request_analysis
			elseif attached l_parser.error_message as al_message then
				status_label.set_text (al_message)
			end
		end

	clear_all
		do
				-- Any analysis still running answers a function that is gone: drop its result.
			requests_sent := requests_sent + 1
			plots.wipe_out
			roots.wipe_out
			function_list.wipe_out
			derivative_value.set_text ("")
			integral_value.set_text ("")
			roots_value.set_text ("")
			status_label.set_text (texts.ready)
			render
			refresh_table
		ensure
			empty: plots.is_empty and roots.is_empty
		end

	request_analysis
			-- Hand the selected function to the worker.
		do
			if attached selected_plot as al_plot then
				status_label.set_text (texts.computing)
				requests_sent := requests_sent + 1
				send_request (analyzer, requests_sent, al_plot.text, number_in (x0_field, 0.0), number_in (lower_field, 0.0),
					number_in (upper_field, {SIMPLE_MATH}.pi), view.x_min, view.x_max)
			else
				status_label.set_text (texts.no_function)
			end
		end

	toggle_hebrew
		do
			texts.set_hebrew (not texts.is_hebrew)
			apply_texts
		end

	toggle_table
		do
			if attached table as al_table and then not al_table.window.is_closed then
				al_table.window.close
				table := Void
			else
				create table.make (Current)
				refresh_table
				if attached table as al_table then
					al_table.window.show
				end
			end
		end

	table_closed
		do
			table := Void
		end

	zoom (a_factor: REAL_64)
		do
			view.zoom (a_factor)
			render
			refresh_table
		end

	reset_view
		do
			view.reset
			render
			refresh_table
		end

	export_png (a_path: PATH): BOOLEAN
			-- Write the current graph to `a_path'.
		do
			render
			if attached last_image as al_image then
				Result := al_image.write_png (a_path.name) and then (create {RAW_FILE}.make_with_path (a_path)).exists
			end
		end

feature -- Drawing

	render
			-- Redraw the graph at the canvas's device size.
		local
			l_image: CAIRO_SURFACE
			w, h: INTEGER
		do
			w := canvas.pixel_width
			h := canvas.pixel_height
			if w > 0 and h > 0 then
				create l_image.make (w, h)
				renderer.render (l_image, view, plots, roots, app.is_dark, canvas.scale_factor)
				canvas.present (l_image)
				if attached last_image as al_old then
					al_old.destroy
				end
				last_image := l_image
			end
		end

	selected_plot: detachable GC_PLOT
		do
			if function_list.selected_index > 0 and function_list.selected_index <= plots.count then
				Result := plots [function_list.selected_index]
			end
		end

feature {NONE} -- Building

	build_menus
			-- Every menu and item is remembered under a key, so `apply_texts' can relabel it.
		local
			l_menu: GUI_MENU
		do
			create menu_titles.make (4)
			create menu_items.make (20)
			l_menu := new_menu ("file")
			l_menu.add_item (texts.menu_text ("open"), "primary+O", agent open_with_dialog)
			remember (l_menu, "open")
			l_menu.add_item (texts.menu_text ("save"), "primary+S", agent save_with_dialog)
			remember (l_menu, "save")
			l_menu.add_separator
			l_menu.add_item (texts.menu_text ("export"), "primary+E", agent export_with_dialog)
			remember (l_menu, "export")
			export_item_id := l_menu.last_item_id
			l_menu.add_separator
			l_menu.add_role_item (l_menu.Role_quit, texts.menu_text ("quit"), "primary+Q", agent app.quit)
			remember (l_menu, "quit")
			l_menu := new_menu ("edit")
			l_menu.add_edit_item (l_menu.Role_undo, texts.menu_text ("undo"))
			remember (l_menu, "undo")
			l_menu.add_edit_item (l_menu.Role_redo, texts.menu_text ("redo"))
			remember (l_menu, "redo")
			l_menu.add_separator
			l_menu.add_edit_item (l_menu.Role_cut, texts.menu_text ("cut"))
			remember (l_menu, "cut")
			l_menu.add_edit_item (l_menu.Role_copy, texts.menu_text ("copy"))
			remember (l_menu, "copy")
			l_menu.add_edit_item (l_menu.Role_paste, texts.menu_text ("paste"))
			remember (l_menu, "paste")
			l_menu.add_edit_item (l_menu.Role_select_all, texts.menu_text ("select_all"))
			remember (l_menu, "select_all")
			l_menu := new_menu ("view")
			l_menu.add_item (texts.menu_text ("zoom_in"), "", agent zoom (0.8))
			remember (l_menu, "zoom_in")
			l_menu.add_item (texts.menu_text ("zoom_out"), "", agent zoom (1.25))
			remember (l_menu, "zoom_out")
			l_menu.add_item (texts.menu_text ("reset_view"), "primary+R", agent reset_view)
			remember (l_menu, "reset_view")
			l_menu.add_separator
			l_menu.add_item (texts.menu_text ("table"), "primary+T", agent toggle_table)
			remember (l_menu, "table")
			table_item_id := l_menu.last_item_id
			l_menu.add_item (texts.menu_text ("language"), "", agent toggle_hebrew)
			remember (l_menu, "language")
			hebrew_item_id := l_menu.last_item_id
			l_menu := new_menu ("help")
			l_menu.add_role_item (l_menu.Role_about, texts.menu_text ("about"), "", agent show_about)
			remember (l_menu, "about")
		end

	new_menu (a_key: STRING): GUI_MENU
			-- A top-level menu titled by `a_key'.
		do
			Result := app.menu.add_menu (texts.menu_text (a_key))
			menu_titles.extend ([Result, a_key])
		end

	remember (a_menu: GUI_MENU; a_key: STRING)
			-- Record `a_menu''s last item under `a_key'.
		do
			menu_items.extend ([a_menu, a_menu.last_item_id, a_key])
		end

	relabel_menus
			-- Put the current language's words on every menu and item.
		do
			across menu_titles as ic loop
				ic.menu.set_title (texts.menu_text (ic.key))
			end
			across menu_items as ic loop
				ic.menu.set_item_text (ic.id, texts.menu_text (ic.key))
			end
		end

	build_window
		local
			l_panel, l_row, l_views: GUI_STACK
			l_keypad, l_inputs, l_results: GUI_GRID
		do
			create root.make_horizontal
			create l_panel.make_vertical
				-- Expression.
			create function_title.make ("")
			create expression_field.make
			l_panel.extend (function_title)
			l_panel.extend (expression_field)
				-- Keypad.
			create l_keypad.make
			create keypad_buttons.make (15)
			create keypad_inserts.make (15)
			add_key (l_keypad, 1, 1, "sin", "sin(", "sine")
			add_key (l_keypad, 1, 2, "cos", "cos(", "cosine")
			add_key (l_keypad, 1, 3, "tan", "tan(", "tangent")
			add_key (l_keypad, 1, 4, "ln", "ln(", "natural logarithm")
			add_key (l_keypad, 1, 5, "√", "√(", "square root")
			add_key (l_keypad, 2, 1, "x", "x", "x")
			add_key (l_keypad, 2, 2, "θ", "θ", "theta")
			add_key (l_keypad, 2, 3, "π", "π", "pi")
			add_key (l_keypad, 2, 4, "e", "e", "e, Euler's number")
			add_key (l_keypad, 2, 5, "^", "^", "to the power of")
			add_key (l_keypad, 3, 1, "x²", "²", "squared")
			add_key (l_keypad, 3, 2, "(", "(", "open parenthesis")
			add_key (l_keypad, 3, 3, ")", ")", "close parenthesis")
			add_key (l_keypad, 3, 4, "·", "·", "times")
			add_key (l_keypad, 3, 5, "−", "−", "minus")
			l_panel.extend (l_keypad)
				-- Plot and Clear.
			create l_row.make_horizontal
			create plot_button.make ("")
			create clear_button.make ("")
			l_row.extend (plot_button)
			l_row.extend (clear_button)
			l_panel.extend (l_row)
				-- Functions.
			create functions_title.make ("")
			l_panel.extend (functions_title)
			create function_list.make
			l_panel.extend_stretching (function_list)
				-- Analysis inputs.
			create analysis_title.make ("")
			l_panel.extend (analysis_title)
			create l_inputs.make
			create x0_field.make
			x0_field.set_text ("0")
			x0_field.set_accessible_label ("x zero")
			create lower_field.make
			lower_field.set_text ("0")
			lower_field.set_accessible_label ("a, lower limit")
			create upper_field.make
			upper_field.set_text ("3.14159")
			upper_field.set_accessible_label ("b, upper limit")
			l_inputs.put (create {GUI_LABEL}.make ("x₀"), 1, 1)
			l_inputs.put (x0_field, 1, 2)
			l_inputs.put (create {GUI_LABEL}.make ("a"), 2, 1)
			l_inputs.put (lower_field, 2, 2)
			l_inputs.put (create {GUI_LABEL}.make ("b"), 3, 1)
			l_inputs.put (upper_field, 3, 2)
			l_panel.extend (l_inputs)
			create analyze_button.make ("")
			l_panel.extend (analyze_button)
				-- Results.
			create l_results.make
			create derivative_title.make ("")
			create integral_title.make ("")
			create roots_title.make ("")
			create derivative_value.make ("")
			create integral_value.make ("")
			create roots_value.make ("")
			l_results.put (derivative_title, 1, 1)
			l_results.put (derivative_value, 1, 2)
			l_results.put (integral_title, 2, 1)
			l_results.put (integral_value, 2, 2)
			l_results.put (roots_title, 3, 1)
			l_results.put (roots_value, 3, 2)
			l_panel.extend (l_results)
			create status_label.make ("")
			l_panel.extend (status_label)
				-- View buttons.
			create l_views.make_horizontal
			create zoom_in_button.make ("")
			create zoom_out_button.make ("")
			create reset_button.make ("")
			l_views.extend (zoom_in_button)
			l_views.extend (zoom_out_button)
			l_views.extend (reset_button)
			l_panel.extend (l_views)
				-- Graph.
			create canvas.make (720, 600)
			canvas.set_accessible_label ("graph")
			root.extend (l_panel)
			root.extend_stretching (canvas)
			window.set_content (root)
		end

	wire_events
			-- Connect the controls' agents (after every control exists).
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > keypad_buttons.count
			loop
				keypad_buttons [i].click_actions.extend (agent insert (keypad_inserts [i]))
				i := i + 1
			end
			expression_field.activate_actions.extend (agent plot_expression)
			plot_button.click_actions.extend (agent plot_expression)
			clear_button.click_actions.extend (agent clear_all)
			function_list.selection_actions.extend (agent (r: INTEGER) do request_analysis; refresh_table end)
			analyze_button.click_actions.extend (agent request_analysis)
			zoom_in_button.click_actions.extend (agent zoom (0.8))
			zoom_out_button.click_actions.extend (agent zoom (1.25))
			reset_button.click_actions.extend (agent reset_view)
			canvas.resize_actions.extend (agent (w, h: INTEGER) do render end)
			canvas.pointer_actions.extend (agent on_pointer)
			canvas.key_actions.extend (agent on_key)
		end

	add_key (a_grid: GUI_GRID; a_row, a_column: INTEGER; a_face, an_insert, a_spoken: STRING_32)
			-- A keypad button showing `a_face', inserting `an_insert', announced as `a_spoken'.
		local
			l_button: GUI_BUTTON
		do
			create l_button.make (a_face)
			l_button.set_accessible_label (a_spoken)
			a_grid.put (l_button, a_row, a_column)
			keypad_buttons.extend (l_button)
			keypad_inserts.extend (an_insert)
		end

	apply_texts
			-- Put the current language's text everywhere, and set the direction.
		do
			window.set_title (texts.title)
			relabel_menus
			function_title.set_text (texts.function_label)
			expression_field.set_placeholder (texts.function_hint)
			expression_field.set_accessible_label (texts.function_label)
			plot_button.set_text (texts.plot)
			clear_button.set_text (texts.clear)
			functions_title.set_text (texts.functions)
			analysis_title.set_text (texts.analysis)
			analyze_button.set_text (texts.analyze)
			derivative_title.set_text (texts.derivative)
			derivative_title.set_accessible_label (texts.derivative_spoken)
			integral_title.set_text (texts.integral)
			integral_title.set_accessible_label (texts.integral_spoken)
			roots_title.set_text (texts.roots)
			zoom_in_button.set_text (texts.zoom_in)
			zoom_out_button.set_text (texts.zoom_out)
			reset_button.set_text (texts.reset_view)
			if status_label.text.is_empty or status_label.text.same_string ("Ready") or status_label.text.same_string ({STRING_32} "מוכן") then
				status_label.set_text (texts.ready)
			end
				-- On the window, so the menu bar mirrors too (it sits outside the content).
			window.set_base_direction (if texts.is_hebrew then root.Direction_right_to_left else root.Direction_left_to_right end)
				-- Expressions and numbers are mathematics: always left to right.
			across {ARRAY [GUI_WIDGET]} <<expression_field, x0_field, lower_field, upper_field, derivative_value, integral_value, roots_value, canvas>> as ic loop
				ic.set_base_direction (root.Direction_left_to_right)
			end
			if attached table as al_table then
				al_table.apply_texts
			end
		end

feature {NONE} -- Events

	insert (a_text: STRING_32)
			-- Append `a_text' to the expression.
		do
			expression_field.set_text (expression_field.text + a_text)
		end

	on_message (a_tag: INTEGER; a_payload: STRING_32)
			-- An analysis result from the worker.
		local
			l_key, l_value: STRING_32
			i: INTEGER
		do
			if a_tag = {GC_ANALYZER}.Result_tag and then request_of (a_payload) = requests_sent then
				analyses_received := analyses_received + 1
				roots.wipe_out
				across a_payload.split ('%N') as ic loop
					i := ic.index_of ('=', 1)
					if i > 1 then
						l_key := ic.substring (1, i - 1)
						l_value := ic.substring (i + 1, ic.count)
						if l_key.same_string ("derivative") then
							derivative_value.set_text (l_value)
						elseif l_key.same_string ("integral") then
							integral_value.set_text (l_value)
						elseif l_key.same_string ("roots") then
							collect_roots (l_value)
							roots_value.set_text (roots_display (l_value))
						elseif l_key.same_string ("error") then
							status_label.set_text (l_value)
						end
					end
				end
				if not status_label.text.same_string (texts.computing) then
					-- an error message stays
				else
					status_label.set_text (texts.ready)
				end
				render
			end
		end

	on_pointer (a_kind, a_x, a_y, a_button, a_modifiers: INTEGER)
			-- Drag to pan.
		do
			if a_kind = 1 then
				is_dragging := True
				drag_x := a_x
				drag_y := a_y
			elseif a_kind = 2 then
				is_dragging := False
			elseif a_kind = 3 and is_dragging and canvas.width > 0 and canvas.height > 0 then
				view.pan_pixels (a_x - drag_x, a_y - drag_y, canvas.width, canvas.height)
				drag_x := a_x
				drag_y := a_y
				render
			end
		end

	on_key (a_code: INTEGER; a_character: CHARACTER_32; a_modifiers: INTEGER)
			-- Arrow keys pan by a tenth; + and - zoom; 0 resets (GDK key values, the shared vocabulary).
		do
			inspect a_code
			when 0xff51 then view.pan (-0.1, 0.0); render
			when 0xff53 then view.pan (0.1, 0.0); render
			when 0xff52 then view.pan (0.0, 0.1); render
			when 0xff54 then view.pan (0.0, -0.1); render
			else
				if a_character = '+' or a_character = '=' then
					zoom (0.8)
				elseif a_character = '-' then
					zoom (1.25)
				elseif a_character = '0' then
					reset_view
				end
			end
		end

	open_with_dialog
		local
			l_session: GC_SESSION
		do
			if attached app.dialogs.open_file ("Open Session", <<"json">>) as al_path then
				create l_session
				if not l_session.open (Current, al_path) and then attached l_session.last_error as al_why then
					status_label.set_text (al_why)
				end
			end
		end

	save_with_dialog
		local
			l_session: GC_SESSION
		do
			if attached app.dialogs.save_file ("Save Session", <<"json">>) as al_path then
				create l_session
				if not l_session.save (Current, al_path) then
					status_label.set_text ("Could not write " + al_path.name)
				end
			end
		end

	export_with_dialog
		do
			if attached app.dialogs.save_file ("Export Graph as PNG", <<"png">>) as al_path then
				if not export_png (al_path) then
					status_label.set_text ("Could not write " + al_path.name)
				end
			end
		end

	show_about
		do
			app.dialogs.inform (texts.title, "A native graphing calculator written in Eiffel on simple_gui, with maths from simple_math and simple_calculus and a grammar generated by Gobo's geyacc.")
		end

feature {NONE} -- Implementation

	renderer: GC_RENDERER
	keypad_inserts: ARRAYED_LIST [STRING_32]
	analyzer: separate GC_ANALYZER
	function_title, functions_title, analysis_title, derivative_title, integral_title, roots_title: GUI_LABEL
	is_dragging: BOOLEAN
	drag_x, drag_y: INTEGER

	send_request (a_analyzer: separate GC_ANALYZER; a_number: INTEGER; a_text: STRING_32; a_x0, a_a, a_b, a_low, a_high: REAL_64)
			-- Copy the request in (synchronous), then start it (asynchronous: no reference argument).
		do
			a_analyzer.set_request (a_number, a_text, a_x0, a_a, a_b, a_low, a_high)
			a_analyzer.analyze
		end

	number_in (a_field: GUI_TEXT_FIELD; a_default: REAL_64): REAL_64
			-- The number typed in `a_field', or `a_default'.
		local
			l_parser: GC_PARSER
		do
			create l_parser.make
			l_parser.parse_text (a_field.text)
			if attached l_parser.last_node as al_node and l_parser.variable_name = Void then
				Result := al_node.value (0.0)
			else
				Result := a_default
			end
		end

	request_of (a_payload: STRING_32): INTEGER
			-- The request number a result answers (its first line, "request=N").
		local
			l_first: STRING_32
		do
			l_first := a_payload.split ('%N').first
			if l_first.starts_with ({STRING_32} "request=") then
				l_first.remove_head (8)
				if l_first.is_integer then
					Result := l_first.to_integer
				end
			end
		end

	Shown_roots: INTEGER = 6
			-- Roots listed in the panel; every root still gets its marker on the graph.

	roots_display (a_text: STRING_32): STRING_32
			-- `a_text' cut to `Shown_roots' values, then an ellipsis.
		local
			l_parts: LIST [STRING_32]
			i: INTEGER
		do
			l_parts := a_text.split (',')
			if l_parts.count <= Shown_roots then
				Result := a_text
			else
				create Result.make (60)
				from i := 1 until i > Shown_roots loop
					if i > 1 then
						Result.append ({STRING_32} ",")
					end
					Result.append (l_parts [i])
					i := i + 1
				end
				Result.append ({STRING_32} ", … (" + l_parts.count.out + {STRING_32} ")")
			end
		end

	collect_roots (a_text: STRING_32)
		do
			across a_text.split (',') as ic loop
				ic.left_adjust
				if ic.is_real_64 then
					roots.extend (ic.to_real_64)
				end
			end
		end

	refresh_table
		do
			if attached table as al_table then
				al_table.refresh
			end
		end

invariant
	plots_and_rows: plots.count = function_list.count

end
