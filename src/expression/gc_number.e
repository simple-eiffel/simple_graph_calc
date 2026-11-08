note
	description: "A constant: a literal number, pi or e."

class
	GC_NUMBER

inherit
	GC_NODE

create
	make

feature {NONE} -- Initialization

	make (a_value: REAL_64)
		do
			number := a_value
		ensure
			set: number = a_value
		end

feature -- Access

	number: REAL_64

feature -- Evaluation

	value (a_x: REAL_64): REAL_64
		do
			Result := number
		ensure then
			constant: Result = number
		end

feature -- Output

	text: STRING_32
		do
			Result := number.out
		end

end
