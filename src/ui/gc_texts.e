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

feature -- Menu texts

	menu_text (a_key: STRING): STRING_32
			-- The menu title or item called `a_key' in the current language. About and Quit
			-- are the bare word: macOS adds the application's name itself.
		do
			if a_key.same_string ("file") then Result := pick ("File", "קובץ")
			elseif a_key.same_string ("edit") then Result := pick ("Edit", "עריכה")
			elseif a_key.same_string ("view") then Result := pick ("View", "תצוגה")
			elseif a_key.same_string ("help") then Result := pick ("Help", "עזרה")
			elseif a_key.same_string ("open") then Result := pick ("Open Session…", "פתח…")
			elseif a_key.same_string ("save") then Result := pick ("Save Session…", "שמור…")
			elseif a_key.same_string ("export") then Result := pick ("Export Graph as PNG…", "ייצא גרף כ־PNG…")
			elseif a_key.same_string ("quit") then Result := pick ("Quit", "יציאה")
			elseif a_key.same_string ("undo") then Result := pick ("Undo", "בטל")
			elseif a_key.same_string ("redo") then Result := pick ("Redo", "בצע שוב")
			elseif a_key.same_string ("cut") then Result := pick ("Cut", "גזור")
			elseif a_key.same_string ("copy") then Result := pick ("Copy", "העתק")
			elseif a_key.same_string ("paste") then Result := pick ("Paste", "הדבק")
			elseif a_key.same_string ("select_all") then Result := pick ("Select All", "בחר הכול")
			elseif a_key.same_string ("zoom_in") then Result := pick ("Zoom In", "הגדל")
			elseif a_key.same_string ("zoom_out") then Result := pick ("Zoom Out", "הקטן")
			elseif a_key.same_string ("reset_view") then Result := pick ("Reset View", "אפס תצוגה")
			elseif a_key.same_string ("table") then Result := pick ("Table of Values", "טבלת ערכים")
				-- The way back is always in English, so a reader who cannot read Hebrew finds it.
			elseif a_key.same_string ("language") then Result := pick ("Hebrew Interface", "English Interface")
			elseif a_key.same_string ("about") then Result := pick ("About", "אודות")
			else
				Result := a_key.to_string_32
			end
		ensure
			not_empty: not Result.is_empty
		end

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
