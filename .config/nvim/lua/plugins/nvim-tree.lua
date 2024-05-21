return {
    "nvim-tree/nvim-tree.lua",
    config = function()
        require("nvim-tree").setup({
            filters = {
                git_ignored = false
            },
            view = {
                float = {
                    enable = true,
                    quit_on_focus_loss = true,
                    open_win_config = {
                        width = 100
                    }
                }
            }
        })

        -- Remap keys for nvimtree
        vim.keymap.set({ 'n', 'v' }, '<leader>-', vim.cmd.NvimTreeFindFile)
        -- vim.keymap.set({ 'n', 'v' }, '<leader>-', vim.cmd.NvimTreeToggle)
    end
}
