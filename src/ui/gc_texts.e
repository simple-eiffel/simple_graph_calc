note
	description: "[
		Interface text in English or Hebrew. The Hebrew interface also mirrors the
		window (right to left); the graph itself keeps mathematical orientation.
		Hebrew wording is machine-written: have a Hebrew reader check it.
	]"

class
	GC_TEXTS

create
	make

feature {NONE} -- Initialization

	make
		do
		end

feature -- Status

	is_hebrew: BOOLEAN

	set_hebrew (a_on: BOOLEAN)
		do
			is_hebrew := a_on
		ensure
			set: is_hebrew = a_on
		end

feature -- Texts

	title: STRING_32 do Result := pick ("Eiffel Graphing Calculator", "מחשבון גרפי באייפל") end
	function_label: STRING_32 do Result := pick ("Function", "פונקציה") end
	function_hint: STRING_32 do Result := pick ("for example sin(x)·e^(−x/4)", "לדוגמה sin(x)·e^(−x/4)") end
	plot: STRING_32 do Result := pick ("Plot", "שרטט") end
	clear: STRING_32 do Result := pick ("Clear", "נקה") end
	functions: STRING_32 do Result := pick ("Functions", "פונקציות") end
	analysis: STRING_32 do Result := pick ("Analysis", "ניתוח") end
	analyze: STRING_32 do Result := pick ("Analyze", "נתח") end
	derivative: STRING_32 do Result := pick ("f′(x₀)", "f′(x₀)") end
	derivative_spoken: STRING_32 do Result := pick ("derivative at x zero", "נגזרת בנקודה x אפס") end
	integral: STRING_32 do Result := pick ("∫ from a to b", "∫ מ־a עד b") end
	integral_spoken: STRING_32 do Result := pick ("integral from a to b", "אינטגרל מ־a עד b") end
	roots: STRING_32 do Result := pick ("Roots", "שורשים") end
	computing: STRING_32 do Result := pick ("Computing…", "מחשב…") end
	ready: STRING_32 do Result := pick ("Ready", "מוכן") end
	zoom_in: STRING_32 do Result := pick ("Zoom in", "הגדל") end
	zoom_out: STRING_32 do Result := pick ("Zoom out", "הקטן") end
	reset_view: STRING_32 do Result := pick ("Reset view", "אפס תצוגה") end
	table_title: STRING_32 do Result := pick ("Table of values", "טבלת ערכים") end
	no_function: STRING_32 do Result := pick ("Plot a function first", "שרטט פונקציה תחילה") end

feature {NONE} -- Implementation

	pick (an_english, a_hebrew: STRING_32): STRING_32
		do
			if is_hebrew then
				Result := a_hebrew
			else
				Result := an_english
			end
		end

end
