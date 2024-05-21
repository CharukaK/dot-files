return {
    "mbbill/undotree",
    config = function()
        -- undotree toggle
        vim.keymap.set('n', '<leader><F5>', vim.cmd.UndotreeToggle)
    end
}
