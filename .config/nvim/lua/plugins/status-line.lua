-- return {
--     'echasnovski/mini.statusline',
--     version = '*',
--     config = function()
--         local statusline = require 'mini.statusline'
--         statusline.setup { use_icons = true }
--     end
-- }

return {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
        require('lualine').setup({
            options = {
                component_seperators = "|",
                section_seperators = "|"
            },
            sections = {
                lualine_a = {
                    { 'mode', fmt = function(str) return str:sub(1, 1) end }
                },
                lualine_c = {
                    {
                        'filename',
                        path = 1
                    }
                }
            }
        })
    end
}
