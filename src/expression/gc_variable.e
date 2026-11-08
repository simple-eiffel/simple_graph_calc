note
	description: "The expression's one variable (x, θ, or any other name that is not a function or constant)."

class
	GC_VARIABLE

inherit
	GC_NODE

create
	make

feature {NONE} -- Initialization

	make (a_name: READABLE_STRING_32)
		require
			named: not a_name.is_empty
		do
			name := a_name.to_string_32
		ensure
			set: name.same_string (a_name)
		end

feature -- Access

	name: STRING_32

feature -- Evaluation

	value (a_x: REAL_64): REAL_64
		do
			Result := a_x
		end

feature -- Output

	text: STRING_32
		do
			Result := name.twin
		end

invariant
	named: not name.is_empty

end
