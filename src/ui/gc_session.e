note
	description: "[
		A saved calculator session, as JSON through simple_json:
		{"format": "simple_graph_calc session", "version": 1,
		 "functions": ["sin(x)", ...], "view": {"x_min": ..., "x_max": ..., "y_min": ..., "y_max": ...},
		 "x0": "0", "a": "0", "b": "3.14159", "hebrew": false}
		Functions are stored as the user typed them and re-parsed on opening.
	]"

class
	GC_SESSION

feature -- Constants

	Format_name: STRING_32 = "simple_graph_calc session"
	Version: INTEGER = 1

feature -- Writing

	text_of (a_main: GC_MAIN_WINDOW): STRING_32
			-- `a_main''s session as JSON text.
		local
			l_json: SIMPLE_JSON
			l_functions: SIMPLE_JSON_ARRAY
			l_view, l_root: SIMPLE_JSON_OBJECT
		do
			create l_json
			l_functions := l_json.new_array
			across a_main.plots as ic loop
				l_functions := l_functions.add_string (ic.text)
			end
			l_view := l_json.new_object
				.put_real (a_main.view.x_min, "x_min").put_real (a_main.view.x_max, "x_max")
				.put_real (a_main.view.y_min, "y_min").put_real (a_main.view.y_max, "y_max")
			l_root := l_json.new_object
				.put_string (Format_name, "format")
				.put_integer (Version, "version")
				.put_array (l_functions, "functions")
				.put_object (l_view, "view")
				.put_string (a_main.x0_field.text, "x0")
				.put_string (a_main.lower_field.text, "a")
				.put_string (a_main.upper_field.text, "b")
				.put_boolean (a_main.texts.is_hebrew, "hebrew")
			Result := l_root.to_pretty_json
		end

	save (a_main: GC_MAIN_WINDOW; a_path: PATH): BOOLEAN
			-- Write `a_main''s session to `a_path' as UTF-8.
		local
			l_file: RAW_FILE
			l_retried: BOOLEAN
		do
			if not l_retried then
				create l_file.make_with_path (a_path)
				l_file.open_write
				l_file.put_string ({UTF_CONVERTER}.utf_32_string_to_utf_8_string_8 (text_of (a_main)))
				l_file.close
				Result := True
			end
		rescue
			l_retried := True
			retry
		end

feature -- Reading

	last_error: detachable STRING_32
			-- Why the last `open' failed.

	open (a_main: GC_MAIN_WINDOW; a_path: PATH): BOOLEAN
			-- Replace `a_main''s session with the one at `a_path'.
		local
			l_json: SIMPLE_JSON
		do
			last_error := Void
			create l_json
			if attached l_json.parse_file (a_path.name) as al_value and then al_value.is_object then
				Result := apply (a_main, al_value.as_object)
			else
				last_error := {STRING_32} "not a JSON file"
			end
		ensure
			reason_on_failure: not Result implies last_error /= Void
		end

feature {NONE} -- Implementation

	apply (a_main: GC_MAIN_WINDOW; a_root: SIMPLE_JSON_OBJECT): BOOLEAN
		local
			i: INTEGER
		do
			if not (attached a_root.string_item ("format") as al_format and then al_format.same_string (Format_name)) then
				last_error := {STRING_32} "not a calculator session"
			elseif a_root.integer_item ("version") > Version then
				last_error := {STRING_32} "made by a newer version"
			else
				a_main.clear_all
				if attached a_root.object_item ("view") as al_view and then
					al_view.real_item ("x_min") < al_view.real_item ("x_max") and then al_view.real_item ("y_min") < al_view.real_item ("y_max")
				then
					a_main.view.set_region (al_view.real_item ("x_min"), al_view.real_item ("x_max"), al_view.real_item ("y_min"), al_view.real_item ("y_max"))
				end
				if attached a_root.string_item ("x0") as al_s then a_main.x0_field.set_text (al_s) end
				if attached a_root.string_item ("a") as al_s then a_main.lower_field.set_text (al_s) end
				if attached a_root.string_item ("b") as al_s then a_main.upper_field.set_text (al_s) end
				if a_root.boolean_item ("hebrew") /= a_main.texts.is_hebrew then
					a_main.toggle_hebrew
				end
				if attached a_root.array_item ("functions") as al_functions then
					from
						i := 1
					until
						i > al_functions.count
					loop
						if attached al_functions.string_item (i) as al_text then
							a_main.expression_field.set_text (al_text)
							a_main.plot_expression
						end
						i := i + 1
					end
				end
				Result := True
			end
		end

end
