note
	description: "A second window: the selected function's values across the visible x range."

class
	GC_TABLE_WINDOW

inherit
	GC_FORMAT

create
	make

feature {NONE} -- Initialization

	make (an_owner: GC_MAIN_WINDOW)
		local
			l_stack: GUI_STACK
		do
			owner := an_owner
			create window.make (an_owner.texts.table_title, 360, 560)
			create l_stack.make_vertical
			create caption.make ("")
			create rows.make
			rows.set_accessible_label (an_owner.texts.table_title)
			l_stack.extend (caption)
			l_stack.extend_stretching (rows)
			window.set_content (l_stack)
			window.close_requested_actions.extend (agent close)
			apply_texts
		end

feature -- Access

	owner: GC_MAIN_WINDOW
	window: GUI_WINDOW
	caption: GUI_LABEL
	rows: GUI_LIST

	Row_count: INTEGER = 21

feature -- Commands

	refresh
			-- Rebuild the rows for the owner's selected function.
		local
			i: INTEGER
			x: REAL_64
			v: GC_VIEW
		do
			rows.wipe_out
			if attached owner.selected_plot as al_plot then
				caption.set_text (al_plot.label)
				v := owner.view
				from
					i := 0
				until
					i >= Row_count
				loop
					x := v.x_min + i * v.x_span / (Row_count - 1)
					rows.extend (al_plot.variable + {STRING_32} " = " + short (x) + {STRING_32} "    f = " + short (al_plot.value (x)))
					i := i + 1
				end
			else
				caption.set_text (owner.texts.no_function)
			end
		end

	apply_texts
		do
			window.set_title (owner.texts.title + {STRING_32} " - " + owner.texts.table_title)
			window.set_base_direction (if owner.texts.is_hebrew then window.Direction_right_to_left else window.Direction_left_to_right end)
			rows.set_base_direction (window.Direction_left_to_right)
		end

	close
		do
			if not window.is_closed then
				window.close
			end
			owner.table_closed
		end

end
