-- [[ Setting options ]]
-- See `:help vim.o`

-- Disable netrw for nvimtree
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Set highlight on search
vim.o.hlsearch = false

-- Make line numbers default
vim.wo.number = true

-- Enable mouse mode
vim.o.mouse = 'a'

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case insensitive searching UNLESS /C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Decrease update time
vim.o.updatetime = 250
vim.wo.signcolumn = 'yes'

-- Set colorscheme
vim.o.termguicolors = true

-- vim.cmd.colorscheme('gruvbox')
vim.cmd [[colorscheme tokyonight]]
-- vim.cmd [[colorscheme onedark]]


-- Set colorscheme
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.smartindent = true
vim.o.wrap = false

-- set number rules
vim.opt.relativenumber = true

-- color column
vim.opt.colorcolumn = "120"

-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menuone,noselect'
