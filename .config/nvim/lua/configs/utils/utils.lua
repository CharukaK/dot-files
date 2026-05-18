local M = {}

M.copy_path_with_line_cols = function()
	-- Get the relative path from the current working directory
	local path = vim.fn.expand("%")
	local mode = vim.api.nvim_get_mode().mode

	local result = path

	-- Check if we are in a visual mode (v, V, or CTRL-V)
	if mode:match("[vV\22]") then
		-- Get visual selection marks
		local _, line_start, _, _ = unpack(vim.fn.getpos("v"))
		local _, line_end, _, _ = unpack(vim.fn.getpos("."))

		-- Standardize order (incase of bottom-to-top selection)
		if line_start > line_end then
			line_start, line_end = line_end, line_start
			col_start, col_end = col_end, col_start
		end

		result = string.format("%s(line: %d:%d)", path, line_start, line_end)

		-- Exit visual mode back to normal mode after copying
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
	end

	-- Copy to system clipboard (+) and unnamed register (")
	vim.fn.setreg("+", result)
	vim.fn.setreg('"', result)

	print("Copied: " .. result)
end

M.setup = function()
	-- Create the Keybindings
	vim.keymap.set(
		{ "n", "v" },
		"<leader>cp",
		M.copy_path_with_line_cols,
		{ desc = "Copy relative path with line/col" }
	)
end

return M
