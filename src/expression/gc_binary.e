note
	description: "A binary operation: + - * / ^."

class
	GC_BINARY

inherit
	GC_NODE

create
	make

feature {NONE} -- Initialization

	make (an_operator: CHARACTER_32; a_left, a_right: GC_NODE)
		require
			known: is_operator (an_operator)
		do
			operator := an_operator
			left := a_left
			right := a_right
		ensure
			set: operator = an_operator and left = a_left and right = a_right
		end

feature -- Access

	operator: CHARACTER_32
	left: GC_NODE
	right: GC_NODE

	is_operator (c: CHARACTER_32): BOOLEAN
		do
			Result := c = '+' or c = '-' or c = '*' or c = '/' or c = '^'
		end

feature -- Evaluation

	value (a_x: REAL_64): REAL_64
		local
			l, r: REAL_64
		do
			l := left.value (a_x)
			r := right.value (a_x)
			inspect operator
			when '+' then
				Result := l + r
			when '-' then
				Result := l - r
			when '*' then
				Result := l * r
			when '/' then
				if r = 0.0 then
					Result := {REAL_64}.nan
				else
					Result := l / r
				end
			else
				Result := power (l, r)
			end
		end

feature -- Output

	text: STRING_32
		do
			Result := {STRING_32} "(" + left.text + {STRING_32} " " + operator.out + {STRING_32} " " + right.text + {STRING_32} ")"
		end

feature {NONE} -- Implementation

	power (a_base, an_exponent: REAL_64): REAL_64
			-- `a_base' ^ `an_exponent'; NaN for a negative base with a non-integer exponent.
		do
			if a_base < 0.0 and an_exponent /= an_exponent.rounded_real_64 then
				Result := {REAL_64}.nan
			else
				Result := a_base ^ an_exponent
			end
		end

invariant
	known: is_operator (operator)

end
