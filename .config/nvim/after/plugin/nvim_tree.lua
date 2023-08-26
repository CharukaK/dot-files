-- file explorer setup
require('nvim-tree').setup()

-- Remap keys for nvimtree
vim.keymap.set({ 'n', 'v' }, '<leader>pe', vim.cmd.NvimTreeFindFile)

