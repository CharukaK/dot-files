-- return {
--     "nvim-tree/nvim-tree.lua",
--     config = function()
--         require("nvim-tree").setup({
--             filters = {
--                 git_ignored = false
--             },
--             view = {
--                 float = {
--                     enable = true,
--                     quit_on_focus_loss = true,
--                     open_win_config = {
--                         width = 100
--                     }
--                 }
--             },
--             renderer = {
--                 group_empty = true,
--             },
--         })
--
--         -- Remap keys for nvimtree
--         vim.keymap.set({ 'n', 'v' }, '-', vim.cmd.NvimTreeFindFile)
--         -- vim.keymap.set({ 'n', 'v' }, '<leader>-', vim.cmd.NvimTreeToggle)
--     end
-- }
return {
    'echasnovski/mini.files',
    version = '*',
    config = function()
        local minifile = require 'mini.files'
        minifile.setup()
        local open_current_file_dir = function()
            -- minifile.open()
            -- if not minifile.close() then minifile.open(...) end
            local current_file = vim.api.nvim_buf_get_name(0)         -- Get the current file's path
            local file_dir = vim.fn.fnamemodify(current_file, ":p:h") -- Extract the directory
            minifile.open(file_dir, false)
        end

        vim.api.nvim_create_autocmd('User', {
            pattern = 'MiniFilesBufferCreate',
            callback = function()
                if vim.fn.argc() == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1 then
                    local arg0 = vim.fn.argv(0)

                    if type(arg0) == "table" then
                        arg0 = arg0[1]
                    end

                    vim.fn.chdir(arg0)
                end
            end
        })

        vim.keymap.set({ 'n' }, '-', open_current_file_dir)
    end
}
