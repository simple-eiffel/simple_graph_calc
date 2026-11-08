note
	description: "Shared test helper: `assert' raises with a message, so the runner reports it."

class
	GC_TEST_SUPPORT

feature {NONE} -- Assertions

	assert (a_tag: READABLE_STRING_GENERAL; a_ok: BOOLEAN)
		local
			l_e: DEVELOPER_EXCEPTION
		do
			if not a_ok then
				create l_e
				l_e.set_description (a_tag)
				l_e.raise
			end
		end

end
