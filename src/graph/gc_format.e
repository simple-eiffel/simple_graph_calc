note
	description: "Short, readable numbers for labels and results."

class
	GC_FORMAT

feature -- Formatting

	short (a_value: REAL_64): STRING_32
			-- `a_value' with up to six decimals, trailing zeros removed; "undefined" for NaN.
		local
			l_rounded: REAL_64
			l_text: STRING
		do
			if a_value.is_nan then
				Result := {STRING_32} "undefined"
			elseif a_value.abs >= 1.0e7 or (a_value /= 0.0 and a_value.abs < 1.0e-5) then
				Result := a_value.out.to_string_32
			else
				l_rounded := (a_value * 1.0e6).rounded_real_64 / 1.0e6
				if l_rounded = 0.0 then
					l_rounded := 0.0
				end
				l_text := (create {FORMAT_DOUBLE}.make (24, 6)).formatted (l_rounded)
				l_text.left_adjust
				if l_text.has ('.') then
					from
					until
						l_text.item (l_text.count) /= '0'
					loop
						l_text.remove_tail (1)
					end
					if l_text.item (l_text.count) = '.' then
						l_text.remove_tail (1)
					end
				end
				if l_text.same_string ("-0") then
					l_text := "0"
				end
				Result := l_text.to_string_32
			end
		ensure
			not_empty: not Result.is_empty
		end

end
