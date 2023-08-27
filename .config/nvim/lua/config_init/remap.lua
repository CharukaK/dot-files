-- [[ Basic Keymaps ]]
-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- set yanking configuration (copy/paste)
vim.keymap.set({ 'n', 'v' }, '<leader>y', [["+y]])
vim.keymap.set({ 'n', 'v' }, '<leader>Y', [["+Y]])

-- -- split navigation
vim.keymap.set("n", "<A-h>", "<C-w>h");
vim.keymap.set("n", "<A-j>", "<C-w>j");
vim.keymap.set("n", "<A-k>", "<C-w>k");
vim.keymap.set("n", "<A-l>", "<C-w>l");

-- set halfpage scroll but everytime cursor is in middle
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- when in visual mode use this to move code highlighted code blocks
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Remap keys for tpope git
vim.keymap.set({ 'n', 'v' }, '<leader>gs', vim.cmd.Git)

-- Remap keys to view Git history for the current file
vim.keymap.set({ 'n', 'v' }, '<leader>gh', ":0Gllog")


-- cursor will stay the same position when using J to remove the end line
vim.keymap.set("n", "J", "mzJ`z")

-- delete without saving to buffer clipboard
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
    callback = function()
        vim.highlight.on_yank()
    end,
    group = highlight_group,
    pattern = '*',
})
