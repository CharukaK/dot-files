-- file explorer setup
require('nvim-tree').setup({
  filters = {
    git_ignored = false
  }
})

-- Remap keys for nvimtree
vim.keymap.set({ 'n', 'v' }, '<leader>pe', vim.cmd.NvimTreeFindFile)
vim.keymap.set({ 'n', 'v' }, '<leader>te', vim.cmd.NvimTreeToggle)
