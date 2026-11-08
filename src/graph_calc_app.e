note
	description: "Eiffel Graphing Calculator: the program."

class
	GRAPH_CALC_APP

create
	make

feature {NONE} -- Initialization

	make
		local
			l_app: GUI_APPLICATION
			l_main: GC_MAIN_WINDOW
		do
			create l_app.make ("Eiffel Graphing Calculator", "org.simple-eiffel.graph-calc")
			if l_app.is_available then
				create l_main.make (l_app)
				l_main.show
				l_app.run
			else
				io.error.put_string ("Eiffel Graphing Calculator needs a display.%N")
			end
		end

end
