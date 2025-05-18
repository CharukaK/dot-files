return {
    {
        "williamboman/mason.nvim",
        config = function()
            require("mason").setup()
        end
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            -- Automatically install LSPs and related tools to stdpath for Neovim
            -- Mason must be loaded before its dependents so we need to set it up here.
            -- NOTE: `opts = {}` is the same as calling `require('mason').setup({})`
            { 'mason-org/mason.nvim', opts = {} },
            'mason-org/mason-lspconfig.nvim',
            'WhoIsSethDaniel/mason-tool-installer.nvim',

            -- Useful status updates for LSP.
            { 'j-hui/fidget.nvim',    opts = {} },

            -- Allows extra capabilities provided by blink.cmp
            'saghen/blink.cmp',
        },
        config = function()
            -- local lspconfig = require("lspconfig")
            -- lspconfig.lua_ls.setup({})
            vim.api.nvim_create_autocmd('LspAttach', {
                group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
                callback = function(event)
                    local telescope = require('telescope.builtin')
                    local map = function(keys, func, desc, mode)
                        if desc then
                            desc = 'LSP: ' .. desc
                        end

                        mode = mode or 'n'

                        vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = desc })
                    end

                    map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
                    map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
                    map('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
                    map('gr', telescope.lsp_references, '[G]oto [R]eferences')
                    map('gI', telescope.lsp_implementations, '[G]oto [I]mplementation')
                    map('gT', telescope.lsp_type_definitions, '[G]oto [T]ype Definition')
                    map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
                    map('<leader>ds', telescope.lsp_document_symbols, '[D]ocument [S]ymbols')
                    map('<leader>ws', telescope.lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

                    map('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
                    map('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
                    map('<leader>wl', function()
                        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
                    end, '[W]orkspace [L]ist Folders')



                    -- Create a command `:Format` local to the LSP buffer
                    vim.api.nvim_buf_create_user_command(
                        event.buf,
                        'Format',
                        function(_)
                            vim.lsp.buf.format()
                        end,
                        { desc = 'Format current buffer with LSP' }
                    )

                    -- The following two autocommands are used to highlight references of the
                    -- word under your cursor when your cursor rests there for a little while.
                    --    See `:help CursorHold` for information about when this is executed
                    --
                    -- When you move your cursor, the highlights will be cleared (the second autocommand).
                    -- local client = vim.lsp.get_client_by_id(event.data.client_id)
                    -- local highlight_augroup = vim.api.nvim_create_augroup('lsp-highlight',
                    --     { clear = false })
                    -- vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
                    --     buffer = event.buf,
                    --     group = highlight_augroup,
                    --     callback = vim.lsp.buf.document_highlight,
                    -- })
                    --
                    -- vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
                    --     buffer = event.buf,
                    --     group = highlight_augroup,
                    --     callback = vim.lsp.buf.clear_references,
                    -- })

                    vim.api.nvim_create_autocmd('LspDetach', {
                        group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
                        callback = function()
                            vim.lsp.buf.clear_references()
                            -- vim.api.nvim_clear_autocmds { group = 'lsp-highlight', buffer = event2.buf }
                        end,
                    })

                    -- map('<leader>th', function()
                    --     vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
                    -- end, '[T]oggle Inlay [H]ints')
                end
            })

            -- Diagnostic Config
            -- See :help vim.diagnostic.Opts
            vim.diagnostic.config {
                severity_sort = true,
                float = { border = 'rounded', source = 'if_many' },
                underline = { severity = vim.diagnostic.severity.ERROR },
                signs = vim.g.have_nerd_font and {
                    text = {
                        [vim.diagnostic.severity.ERROR] = '󰅚 ',
                        [vim.diagnostic.severity.WARN] = '󰀪 ',
                        [vim.diagnostic.severity.INFO] = '󰋽 ',
                        [vim.diagnostic.severity.HINT] = '󰌶 ',
                    },
                } or {},
                virtual_text = {
                    source = 'if_many',
                    spacing = 2,
                    format = function(diagnostic)
                        local diagnostic_message = {
                            [vim.diagnostic.severity.ERROR] = diagnostic.message,
                            [vim.diagnostic.severity.WARN] = diagnostic.message,
                            [vim.diagnostic.severity.INFO] = diagnostic.message,
                            [vim.diagnostic.severity.HINT] = diagnostic.message,
                        }
                        return diagnostic_message[diagnostic.severity]
                    end,
                },
            }

            -- LSP servers and clients are able to communicate to each other what features they support.
            --  By default, Neovim doesn't support everything that is in the LSP specification.
            --  When you add blink.cmp, luasnip, etc. Neovim now has *more* capabilities.
            --  So, we create new capabilities with blink.cmp, and then broadcast that to the servers.
            local capabilities = require('blink.cmp').get_lsp_capabilities()

            -- Enable the following language servers
            --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
            --
            --  Add any additional override configuration in the following tables. Available keys are:
            --  - cmd (table): Override the default command used to start the server
            --  - filetypes (table): Override the default list of associated filetypes for the server
            --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
            --  - settings (table): Override the default settings passed when initializing the server.
            --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
            local servers = {
                -- clangd = {},
                -- gopls = {},
                -- pyright = {},
                -- rust_analyzer = {},
                -- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
                --
                -- Some languages (like typescript) have entire language plugins that can be useful:
                --    https://github.com/pmizio/typescript-tools.nvim
                --
                -- But for many setups, the LSP (`ts_ls`) will work just fine
                -- ts_ls = {},
                --

                lua_ls = {
                    -- cmd = { ... },
                    -- filetypes = { ... },
                    -- capabilities = {},
                    settings = {
                        Lua = {
                            completion = {
                                callSnippet = 'Replace',
                            },
                            -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
                            -- diagnostics = { disable = { 'missing-fields' } },
                        },
                    },
                },
            }

            -- Ensure the servers and tools above are installed
            --
            -- To check the current status of installed tools and/or manually install
            -- other tools, you can run
            --    :Mason
            --
            -- You can press `g?` for help in this menu.
            --
            -- `mason` had to be setup earlier: to configure its options see the
            -- `dependencies` table for `nvim-lspconfig` above.
            --
            -- You can add other tools here that you want Mason to install
            -- for you, so that they are available from within Neovim.
            local ensure_installed = vim.tbl_keys(servers or {})
            vim.list_extend(ensure_installed, {
                'stylua', -- Used to format Lua code
            })
            require('mason-tool-installer').setup { ensure_installed = ensure_installed }

            require('mason-lspconfig').setup {
                ensure_installed = {}, -- explicitly set to an empty table (Kickstart populates installs via mason-tool-installer)
                automatic_installation = false,
                automatic_enable = true,
                handlers = {
                    function(server_name)
                        local server = servers[server_name] or {}
                        -- This handles overriding only values explicitly passed
                        -- by the server configuration above. Useful when disabling
                        -- certain features of an LSP (for example, turning off formatting for ts_ls)
                        server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
                        require('lspconfig')[server_name].setup(server)
                    end,
                },
            }
        end
    },
    {
        -- Autocompletion
        'hrsh7th/nvim-cmp',
        event = 'InsertEnter',
        dependencies = {
            -- Snippet Engine & its associated nvim-cmp source
            {
                'L3MON4D3/LuaSnip',
                build = (function()
                    -- Build Step is needed for regex support in snippets.
                    -- This step is not supported in many windows environments.
                    -- Remove the below condition to re-enable on windows.
                    if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
                        return
                    end
                    return 'make install_jsregexp'
                end)(),
                dependencies = {
                    -- `friendly-snippets` contains a variety of premade snippets.
                    --    See the README about individual language/framework/plugin snippets:
                    --    https://github.com/rafamadriz/friendly-snippets
                    -- {
                    --   'rafamadriz/friendly-snippets',
                    --   config = function()
                    --     require('luasnip.loaders.from_vscode').lazy_load()
                    --   end,
                    -- },
                },
            },
            'saadparwaiz1/cmp_luasnip',

            -- Adds other completion capabilities.
            --  nvim-cmp does not ship with all sources by default. They are split
            --  into multiple repos for maintenance purposes.
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-path',
            -- 'hrsh7th/cmp-nvim-lsp-signature-help',
        },
        config = function()
            -- See `:help cmp`
            local cmp = require 'cmp'
            local luasnip = require 'luasnip'
            luasnip.config.setup {}

            cmp.setup {
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                completion = { completeopt = 'menu,menuone,noinsert' },

                -- For an understanding of why these mappings were
                -- chosen, you will need to read `:help ins-completion`
                --
                -- No, but seriously. Please read `:help ins-completion`, it is really good!
                mapping = cmp.mapping.preset.insert {
                    -- Select the [n]ext item
                    ['<C-n>'] = cmp.mapping.select_next_item(),
                    -- Select the [p]revious item
                    ['<C-p>'] = cmp.mapping.select_prev_item(),

                    -- Scroll the documentation window [b]ack / [f]orward
                    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                    ['<C-f>'] = cmp.mapping.scroll_docs(4),

                    -- Accept ([y]es) the completion.
                    --  This will auto-import if your LSP supports it.
                    --  This will expand snippets if the LSP sent a snippet.
                    ['<C-y>'] = cmp.mapping.confirm { select = true },

                    -- If you prefer more traditional completion keymaps,
                    -- you can uncomment the following lines
                    ['<CR>'] = cmp.mapping.confirm { select = true },
                    --['<Tab>'] = cmp.mapping.select_next_item(),
                    --['<S-Tab>'] = cmp.mapping.select_prev_item(),

                    -- Manually trigger a completion from nvim-cmp.
                    --  Generally you don't need this, because nvim-cmp will display
                    --  completions whenever it has completion options available.
                    ['<C-Space>'] = cmp.mapping.complete {},

                    -- Think of <c-l> as moving to the right of your snippet expansion.
                    --  So if you have a snippet that's like:
                    --  function $name($args)
                    --    $body
                    --  end
                    --
                    -- <c-l> will move you to the right of each of the expansion locations.
                    -- <c-h> is similar, except moving you backwards.
                    ['<C-l>'] = cmp.mapping(function()
                        if luasnip.expand_or_locally_jumpable() then
                            luasnip.expand_or_jump()
                        end
                    end, { 'i', 's' }),
                    ['<C-h>'] = cmp.mapping(function()
                        if luasnip.locally_jumpable(-1) then
                            luasnip.jump(-1)
                        end
                    end, { 'i', 's' }),

                    -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
                    --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
                },
                sources = {
                    { name = 'nvim_lsp' },
                    { name = 'luasnip' },
                    { name = 'path' },
                    { name = 'vim-dadbod-completion' },
                    -- { name = 'nvim_lsp_signature_help' },
                },
            }
        end,
    },
    -- {
    --     'saghen/blink.cmp',
    --     -- optional: provides snippets for the snippet source
    --     dependencies = {
    --         'rafamadriz/friendly-snippets',
    --         { 'kristijanhusak/vim-dadbod-completion', ft = { 'sql', 'mysql', 'plsql' }, lazy = true }, -- Optional
    --     },
    --
    --     -- use a release tag to download pre-built binaries
    --     version = 'v0.*',
    --     -- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
    --     -- build = 'cargo build --release',
    --     -- If you use nix, you can build from source using latest nightly rust with:
    --     -- build = 'nix run .#build-plugin',
    --
    --     opts = {
    --         -- 'default' for mappings similar to built-in completion
    --         -- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys to navigate)
    --         -- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
    --         -- see the "default configuration" section below for full documentation on how to define
    --         -- your own keymap.
    --         keymap = {
    --             preset = 'default',
    --             ['<Tab>'] = {
    --                 function(cmp)
    --                     if cmp.snippet_active() then
    --                         return cmp.accept()
    --                     else
    --                         return cmp.select_and_accept()
    --                     end
    --                 end,
    --                 'snippet_forward',
    --                 'fallback'
    --             },
    --             ['<S-Tab>'] = { 'snippet_backward', 'fallback' },
    --             -- ['<CR>'] = { 'accept', 'fallback' },
    --         },
    --         enabled = function()
    --             -- return not vim.tbl_contains({ "AvanteInput", "Avante" }, vim.bo.filetype) and vim.bo.buftype ~= "prompt" and
    --             --     vim.b.completion ~= false
    --             return vim.bo.buftype ~= "prompt" and vim.b.completion ~= false
    --         end,
    --         appearance = {
    --             -- Sets the fallback highlight groups to nvim-cmp's highlight groups
    --             -- Useful for when your theme doesn't support blink.cmp
    --             -- will be removed in a future release
    --             -- use_nvim_cmp_as_default = true,
    --             -- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
    --             -- Adjusts spacing to ensure icons are aligned
    --             nerd_font_variant = 'mono'
    --         },
    --
    --         -- default list of enabled providers defined so that you can extend it
    --         -- elsewhere in your config, without redefining it, due to `opts_extend`
    --         sources = {
    --             default = { 'lsp', 'path', 'snippets', 'buffer' },
    --             providers = {
    --                 avante_commands = {
    --                     name = "avante_commands",
    --                     module = "blink.compat.source",
    --                     score_offset = 90, -- show at a higher priority than lsp
    --                     opts = {},
    --                 },
    --                 avante_files = {
    --                     name = "avante_commands",
    --                     module = "blink.compat.source",
    --                     score_offset = 100, -- show at a higher priority than lsp
    --                     opts = {},
    --                 },
    --                 avante_mentions = {
    --                     name = "avante_mentions",
    --                     module = "blink.compat.source",
    --                     score_offset = 1000, -- show at a higher priority than lsp
    --                     opts = {},
    --                 },
    --             },
    --             -- optionally disable cmdline completions
    --         },
    --         cmdline = {
    --             enabled = false
    --         },
    --
    --         -- experimental signature help support
    --         signature = { enabled = true },
    --
    --         completion = {
    --             documentation = {
    --                 auto_show = true
    --             }
    --         }
    --     },
    --     -- allows extending the providers array elsewhere in your config
    --     -- without having to redefine it
    -- },
}
