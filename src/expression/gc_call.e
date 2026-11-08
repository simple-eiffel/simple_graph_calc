note
	description: "[
		A function applied to one argument. The functions come from simple_math.
		Angles are in radians. Outside a function's domain the value is NaN, which
		the graph shows as a gap.
	]"

class
	GC_CALL

inherit
	GC_NODE

create
	make

feature {NONE} -- Initialization

	make (a_name: READABLE_STRING_32; an_argument: GC_NODE)
		require
			known: is_function (a_name)
		do
			name := a_name.to_string_32
			argument := an_argument
		ensure
			set: name.same_string (a_name) and argument = an_argument
		end

feature -- Access

	name: STRING_32
	argument: GC_NODE

feature -- Status

	is_function (a_name: READABLE_STRING_32): BOOLEAN
			-- Is `a_name' a function this calculator knows?
		do
			Result := Function_names.has (a_name.to_string_32)
		end

	Function_names: ARRAY [STRING_32]
			-- Every function, in the order the keypad offers them.
		once
			Result := <<{STRING_32} "sin", {STRING_32} "cos", {STRING_32} "tan", {STRING_32} "asin", {STRING_32} "acos",
				{STRING_32} "atan", {STRING_32} "sinh", {STRING_32} "cosh", {STRING_32} "tanh", {STRING_32} "sqrt",
				{STRING_32} "cbrt", {STRING_32} "exp", {STRING_32} "ln", {STRING_32} "log", {STRING_32} "abs">>
			Result.compare_objects
		end

feature -- Evaluation

	value (a_x: REAL_64): REAL_64
		local
			v: REAL_64
		do
			v := argument.value (a_x)
			if v.is_nan then
				Result := v
			elseif name.same_string ("sin") then
				Result := math.sin (v)
			elseif name.same_string ("cos") then
				Result := math.cos (v)
			elseif name.same_string ("tan") then
				Result := math.tan (v)
			elseif name.same_string ("asin") then
				Result := if v.abs <= 1.0 then math.asin (v) else {REAL_64}.nan end
			elseif name.same_string ("acos") then
				Result := if v.abs <= 1.0 then math.acos (v) else {REAL_64}.nan end
			elseif name.same_string ("atan") then
				Result := math.atan (v)
			elseif name.same_string ("sinh") then
				Result := (math.exp (v) - math.exp (-v)) / 2.0
			elseif name.same_string ("cosh") then
				Result := (math.exp (v) + math.exp (-v)) / 2.0
			elseif name.same_string ("tanh") then
				Result := math.tanh (v)
			elseif name.same_string ("sqrt") then
				Result := if v >= 0.0 then math.sqrt (v) else {REAL_64}.nan end
			elseif name.same_string ("cbrt") then
				Result := math.cbrt (v)
			elseif name.same_string ("exp") then
				Result := math.exp (v)
			elseif name.same_string ("ln") then
				Result := if v > 0.0 then math.log (v) else {REAL_64}.nan end
			elseif name.same_string ("log") then
				Result := if v > 0.0 then math.log10 (v) else {REAL_64}.nan end
			else
				Result := v.abs
			end
		end

feature -- Output

	text: STRING_32
		do
			Result := name + {STRING_32} "(" + argument.text + {STRING_32} ")"
		end

feature {NONE} -- Implementation

	math: SIMPLE_MATH
		once
			create Result.make
		end

invariant
	known: is_function (name)

end
