-- return {
--     "catppuccin/nvim",
--     name = "catppuccin",
--     priority = 1000,
--     config = function()
--         -- theme setup
--         require("catppuccin").setup({
--             flavor = "mocha",
--         })
--         vim.cmd.colorscheme "catppuccin"
--     end
-- }
return {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
    config = function()
        require("tokyonight.theme").setup()
        vim.cmd[[colorscheme tokyonight-night]]
    end
}
