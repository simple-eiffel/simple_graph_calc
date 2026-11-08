note
	description: "Unary minus."

class
	GC_NEGATE

inherit
	GC_NODE

create
	make

feature {NONE} -- Initialization

	make (an_operand: GC_NODE)
		do
			operand := an_operand
		ensure
			set: operand = an_operand
		end

feature -- Access

	operand: GC_NODE

feature -- Evaluation

	value (a_x: REAL_64): REAL_64
		do
			Result := - operand.value (a_x)
		end

feature -- Output

	text: STRING_32
		do
			Result := {STRING_32} "(-" + operand.text + {STRING_32} ")"
		end

end
