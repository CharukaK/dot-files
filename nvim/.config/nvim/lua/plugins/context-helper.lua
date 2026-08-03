return {
	dir = "/home/charuka/repos/context-helper",
    depedencies = {
        "MunifTanjim/nui.nvim",
    },
	config = function()
		local context_helper = require("context-helper")
		context_helper.setup({
			on_open_session = function(annotations)
				-- Copy to system clipboard (+) and unnamed register (")
				local fmt_ann = context_helper.format_annotations(annotations, "markdown")
				vim.fn.setreg("+", fmt_ann)
				vim.fn.setreg('"', fmt_ann)
			end,
		})

		vim.keymap.set("v", "<leader>as", context_helper.prompt_for_comment, { desc = "Annotate selection" })
		vim.keymap.set("n", "<leader>al", context_helper.open_quickfix_list, { desc = "show annotation quickfix list" })
		vim.keymap.set("n", "<leader>af", context_helper.annotate_file, { desc = "Annotate file" })
		vim.keymap.set("n", "<leader>ac", context_helper.copy_annotations_to_clipboard, { desc = "Copy annotations" })
		vim.keymap.set("n", "<leader>ao", ":OpenSession<CR>", { desc = "Open annotation session" })
		vim.keymap.set("n", "<leader>ar", ":ResetAnnotations<CR>", { desc = "Reset annotations" })
	end,
}
