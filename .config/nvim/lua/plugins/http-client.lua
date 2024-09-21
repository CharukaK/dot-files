return {
    "rest-nvim/rest.nvim",
    dependencies = { 'nvim-neotest/nvim-nio' },
    config = function ()
        vim.keymap.set('n', '<leader>rr', ":Rest run<CR>")
    end
}
