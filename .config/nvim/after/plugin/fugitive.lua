-- remap keys for tpope git
vim.keymap.set({'n', 'v'}, '<leader>gs', vim.cmd.Git)

-- Remap keys to view Git history for the current file
vim.keymap.set({'n', 'v'}, '<leader>gh', ":0Gllog<CR>")

-- remap keys to view git blame
vim.keymap.set({'n', 'v'}, '<leader>gb', ":Git blame<CR>")

