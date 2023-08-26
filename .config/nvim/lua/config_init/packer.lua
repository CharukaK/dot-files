-- Install packer
local install_path = vim.fn.stdpath 'data' .. '/site/pack/packer/start/packer.nvim'
local is_bootstrap = false
if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
    is_bootstrap = true
    vim.fn.system { 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path }
    vim.cmd.packadd('packer.nvim')
end

require('packer').startup(function(use)
    -- Package manager
    use 'wbthomason/packer.nvim'
    -- file browser
    use {
        'nvim-tree/nvim-tree.lua',
        requires = {
            'nvim-tree/nvim-web-devicons', -- optional, for file icons
        },
    }

    use "github/copilot.vim"

    use { -- autoclose brackets, qoutes etc
        "windwp/nvim-autopairs",
        config = function() require("nvim-autopairs").setup {} end
    }

    use { -- LSP Configuration & Plugins
        'neovim/nvim-lspconfig',
        requires = {
            -- Automatically install LSPs to stdpath for neovim
            'williamboman/mason.nvim',
            'williamboman/mason-lspconfig.nvim',

            -- Useful status updates for LSP
            'j-hui/fidget.nvim',

            -- Additional lua configuration, makes nvim stuff amazing
            'folke/neodev.nvim',
        },
    }
    use { -- Autocompletion
        'hrsh7th/nvim-cmp',
        requires = { 'hrsh7th/cmp-nvim-lsp', 'L3MON4D3/LuaSnip', 'saadparwaiz1/cmp_luasnip' },
    }

    -- use { -- Highlight, edit, and navigate code
    --   'nvim-treesitter/nvim-treesitter',
    --   run = function()
    --     pcall(require('nvim-treesitter.install').update { with_sync = true })
    --   end,
    -- }

    use({ 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' })
    -- use 'nvim-treesitter/nvim-treesitter-context'
    use { -- Additional text objects via treesitter
        'nvim-treesitter/nvim-treesitter-textobjects',
        after = 'nvim-treesitter',
    }

    -- Git related plugins
    use 'tpope/vim-fugitive'
    use 'tpope/vim-rhubarb'
    use 'lewis6991/gitsigns.nvim'

    -- theme
    -- use 'navarasu/onedark.nvim' -- Theme inspired by Atom
    -- use { "ellisonleao/gruvbox.nvim" }
    use 'folke/tokyonight.nvim'
    -- use 'Mofiqul/vscode.nvim'

    use 'nvim-lualine/lualine.nvim'           -- Fancier statusline
    use 'lukas-reineke/indent-blankline.nvim' -- Add indentation guides even on blank lines
    use 'numToStr/Comment.nvim'               -- "gc" to comment visual regions/lines
    use 'tpope/vim-sleuth'                    -- Detect tabstop and shiftwidth automatically

    -- Fuzzy Finder (files, lsp, etc)
    use { 'nvim-telescope/telescope.nvim', branch = '0.1.x', requires = { 'nvim-lua/plenary.nvim' } }

    -- Fuzzy Finder Algorithm which requires local dependencies to be built. Only load if `make` is available
    use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make', cond = vim.fn.executable 'make' == 1 }

    -- debug adapter protocol
    use 'mfussenegger/nvim-dap'

    -- undo tree
    use 'mbbill/undotree'

    -- use {
    --   "mfussenegger/nvim-dap",
    --   opt = true,
    --   module = { "dap" },
    --   requires = {
    --     "theHamsta/nvim-dap-virtual-text",
    --     "rcarriga/nvim-dap-ui",
    --     "mfussenegger/nvim-dap-python",
    --     "nvim-telescope/telescope-dap.nvim",
    --     { "leoluz/nvim-dap-go",                module = "dap-go" },
    --     { "jbyuki/one-small-step-for-vimkind", module = "osv" },
    --     { "mxsdev/nvim-dap-vscode-js" },
    --     {
    --       "microsoft/vscode-js-debug",
    --       opt = true,
    --       run = "npm install --legacy-peer-deps && npm run compile",
    --     },
    --   },
    --   config = function()
    --     require("config.dap").setup()
    --   end,
    --   disable = false,
    -- }

    -- Add custom plugins to packer from ~/.config/nvim/lua/custom/plugins.lua
    local has_plugins, plugins = pcall(require, 'custom.plugins')
    if has_plugins then
        plugins(use)
    end

    if is_bootstrap then
        require('packer').sync()
    end
end)

-- When we are bootstrapping a configuration, it doesn't
-- make sense to execute the rest of the init.lua.
--
-- You'll need to restart nvim, and then it will work.
if is_bootstrap then
    print '=================================='
    print '    Plugins are being installed'
    print '    Wait until Packer completes,'
    print '       then restart nvim'
    print '=================================='
    return
end

-- Automatically source and re-compile packer whenever you save this init.lua
local packer_group = vim.api.nvim_create_augroup('Packer', { clear = true })
vim.api.nvim_create_autocmd('BufWritePost', {
    command = 'source <afile> | PackerCompile',
    group = packer_group,
    pattern = vim.fn.expand '$MYVIMRC',
})
