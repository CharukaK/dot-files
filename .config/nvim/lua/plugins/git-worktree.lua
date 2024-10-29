return {
    "ThePrimeagen/git-worktree.nvim",
    dependencies = {
        'nvim-lua/plenary.nvim',
        'nvim-telescope/telescope.nvim',
    },
    config = function()
        local gwt = require 'git-worktree'
        local telescope = require 'telescope'
        gwt.setup()
        telescope.setup()
        telescope.load_extension("git_worktree")
        vim.keymap.set('n', '<leader>gwt', telescope.extensions.git_worktree.git_worktrees,
            { desc = 'Go to Work tree' })
        vim.keymap.set('n', '<leader>cwt', telescope.extensions.git_worktree.create_git_worktree,
            { desc = 'Create Git Work tree' })
    end
}
