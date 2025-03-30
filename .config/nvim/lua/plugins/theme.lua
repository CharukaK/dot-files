-- return {
--     "shaunsingh/nord.nvim",
--     config = function()
--         --Lua:
--         -- require "nord".setup()
--         vim.cmd [[colorscheme nord]]
--     end
-- }
return {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
        -- theme setup
        require("catppuccin").setup({
            -- flavor = "mocha",
            flavor = "frappe",
        })
        vim.cmd.colorscheme "catppuccin-frappe"
    end
}
-- return {
--     "folke/tokyonight.nvim",
--     lazy = false,
--     priority = 1000,
--     opts = {},
--     config = function()
--         require("tokyonight.theme").setup()
--         vim.cmd[[colorscheme tokyonight-night]]
--     end
-- }
