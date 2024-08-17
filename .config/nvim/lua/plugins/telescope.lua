return {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.6',
    dependencies = {
        'nvim-lua/plenary.nvim',
        { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' }
    },
    opts = {
        defaults = {
            mappings = {
                i = {
                    ['<C-u>'] = false,
                    ['<C-d>'] = false,
                },
            },
        },
        pickers = {
            find_files = {
                hidden = true,
                file_ignore_patterns = { '.git/', 'node_modules/' },
            },
            live_grep = {
                hidden = true,
                file_ignore_patterns = { '.git/', 'node_modules/' },
            }

        },
    },
    config = function(_, opts)
        -- telescope setup
        require('telescope').setup(opts)
        require('telescope').load_extension('fzf')
        local builtin = require('telescope.builtin')
        -- -- Enable telescope fzf native, if installed
        -- pcall(require('telescope').load_extension, 'fzf')
        -- See `:help telescope.builtin`
        vim.keymap.set('n', '<leader>?', builtin.oldfiles, { desc = '[?] Find recently opened files' })
        vim.keymap.set('n', '<leader><space>', builtin.buffers, { desc = '[ ] Find existing buffers' })
        vim.keymap.set('n', '<leader>/', function()
            -- You can pass additional configuration to telescope to change theme, layout, etc.
            builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
                winblend = 10,
                previewer = false,
            })
        end, { desc = '[/] Fuzzily search in current buffer]' })

        vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
        vim.keymap.set('n', '<leader>ss', builtin.git_files, { desc = '[S]earch [F]iles' })
        vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
        vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
        vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
        vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })

        vim.filetype.add({
            extension = {
                templ = "templ",
            },
        })
    end
}
