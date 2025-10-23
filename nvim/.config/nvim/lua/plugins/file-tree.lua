return {
    {
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
                },
                renderer = {
                    group_empty = true,
                },
            })

            -- Remap keys for nvimtree
            vim.keymap.set({ 'n', 'v' }, 'tt', vim.cmd.NvimTreeFindFile)
            -- vim.keymap.set({ 'n', 'v' }, '<leader>-', vim.cmd.NvimTreeToggle)
        end
    },
    -- {
    --     'stevearc/oil.nvim',
    --     ---@module 'oil'
    --     ---@type oil.SetupOpts
    --     opts = {},
    --     -- Optional dependencies
    --     dependencies = { { "echasnovski/mini.icons", opts = {} } },
    --     -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
    --     -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
    --     lazy = false,
    --     config = function()
    --         require("oil").setup()
    --         vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
    --     end
    -- }
    {
        'echasnovski/mini.files',
        version = '*',
        config = function()
            local minifile = require 'mini.files'
            minifile.setup({
                mappings = {
                    go_in       = '<CR>', -- return 
                    go_in_plus  = '<S-l>', -- shift return
                    go_out      = '-',
                },
            })
            local open_current_file_dir = function()
                -- minifile.open()
                -- if not minifile.close() then minifile.open(...) end
                local current_file = vim.api.nvim_buf_get_name(0)         -- Get the current file's path
                local file_dir = vim.fn.fnamemodify(current_file, ":p:h") -- Extract the directory
                minifile.open(file_dir, false)
            end

            local map_split = function(buf_id, lhs, direction)
                local rhs = function()
                    -- Make new window and set it as target
                    local cur_target = MiniFiles.get_explorer_state().target_window
                    local new_target = vim.api.nvim_win_call(cur_target, function()
                        vim.cmd(direction .. ' split')
                        return vim.api.nvim_get_current_win()
                    end)

                    MiniFiles.set_target_window(new_target)

                    -- This intentionally doesn't act on file under cursor in favor of
                    -- explicit "go in" action (`l` / `L`). To immediately open file,
                    -- add appropriate `MiniFiles.go_in()` call instead of this comment.
                end

                -- Adding `desc` will result into `show_help` entries
                local desc = 'Split ' .. direction
                vim.keymap.set('n', lhs, rhs, { buffer = buf_id, desc = desc })
            end

            vim.api.nvim_create_autocmd('User', {
                pattern = 'MiniFilesBufferCreate',
                callback = function(args)
                    if vim.fn.argc() == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1 then
                        local arg0 = vim.fn.argv(0)

                        if type(arg0) == "table" then
                            arg0 = arg0[1]
                        end

                        vim.fn.chdir(arg0)
                    end

                    local buf_id = args.data.buf_id
                    -- split function
                    map_split(buf_id, '<C-s>', 'belowright horizontal')
                    map_split(buf_id, '<C-v>', 'belowright vertical')
                end
            })

            vim.keymap.set({ 'n' }, '-', open_current_file_dir)
        end
    }
}
