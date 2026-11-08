note
	description: "A node of a parsed expression: a function of one variable."

deferred class
	GC_NODE

feature -- Evaluation

	value (a_x: REAL_64): REAL_64
			-- The node's value when the variable is `a_x' (NaN where undefined).
		deferred
		end

feature -- Output

	text: STRING_32
			-- The node written back out, fully parenthesized.
		deferred
		end

end
