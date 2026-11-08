note
	description: "One function on the graph: its text, parsed tree and colour."

class
	GC_PLOT

create
	make

feature {NONE} -- Initialization

	make (a_text: READABLE_STRING_32; a_node: GC_NODE; a_variable: detachable READABLE_STRING_32; a_color: NATURAL_32)
		do
			text := a_text.to_string_32
			node := a_node
			if attached a_variable as al_v then
				variable := al_v.to_string_32
			else
				variable := {STRING_32} "x"
			end
			color := a_color
		ensure
			text_set: text.same_string (a_text)
			node_set: node = a_node
		end

feature -- Access

	text: STRING_32
			-- As the user typed it.

	node: GC_NODE

	variable: STRING_32
			-- The variable's name (x when the expression has none).

	color: NATURAL_32
			-- 0xRRGGBB.

	value (a_x: REAL_64): REAL_64
		do
			Result := node.value (a_x)
		end

	label: STRING_32
			-- "f(x) = text" style caption.
		do
			Result := {STRING_32} "f(" + variable + {STRING_32} ") = " + text
		end

end
