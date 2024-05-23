return {
    {
        "CopilotC-Nvim/CopilotChat.nvim",
        branch = "canary",
        dependencies = {
            { "github/copilot.vim" },    -- or github/copilot.vim
            { "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
        },
        opts = {
            debug = false, -- Enable debugging
            -- See Configuration section for rest
        },
        -- See Commands section for default commands if you want to lazy load on them
        config = function(_, opts)
            local chat = require("CopilotChat")
            chat.setup(opts)
            local quickChat = function()
                local input = vim.fn.input("Quick Chat: ")
                if input ~= "" then
                    chat.ask(input, { selection = require("CopilotChat.select").buffer })
                end
            end

            vim.keymap.set({ "n", "v" }, "<leader>ccq", quickChat, { desc = "Quick Chat" })
        end
    },
}
