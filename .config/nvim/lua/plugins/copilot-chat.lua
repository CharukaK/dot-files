return {
    {
        "yetone/avante.nvim",
        event = "VeryLazy",
        lazy = true,
        version = false,          -- set this if you want to always pull the latest change
        opts = {
            provider = "copilot", -- Recommend using Claude
            auto_suggestions_provider = "copilot",
            hints = { enabled = false },
            mappings = {
                ask = "<leader>ccq",     -- ask
                edit = "<leader>cce",    -- edit
                refresh = "<leader>ccr", -- refresh
            }
            -- add any opts here
        },
        -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
        build = "make",
        -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
        dependencies = {
            "stevearc/dressing.nvim",
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            --- The below dependencies are optional,
            "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
            -- "zbirenbaum/copilot.lua",      -- for providers='copilot'
            "github/copilot.vim",
            {
                -- support for image pasting
                "HakonHarnes/img-clip.nvim",
                event = "VeryLazy",
                opts = {
                    -- recommended settings
                    default = {
                        embed_image_as_base64 = false,
                        prompt_for_file_name = false,
                        drag_and_drop = {
                            insert_mode = true,
                        },
                        -- required for Windows users
                        use_absolute_path = true,
                    },
                },
            },
            {
                -- Make sure to set this up properly if you have lazy=true
                'MeanderingProgrammer/render-markdown.nvim',
                opts = {
                    file_types = { "markdown", "Avante" },
                },
                ft = { "markdown", "Avante" },
            },
        },
    }
    -- {
    --     "CopilotC-Nvim/CopilotChat.nvim",
    --     branch = "canary",
    --     dependencies = {
    --         { "zbirenbaum/copilot.lua" }, -- or github/copilot.vim
    --         { "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
    --     },
    --     build = "make tiktoken",    -- Only on MacOS or Linux
    --     opts = {
    --         debug = false,          -- Enable debugging
    --         -- See Configuration section for rest
    --     },
    --     -- See Commands section for default commands if you want to lazy load on them
    --     config = function(_, opts)
    --         local chat = require("CopilotChat")
    --         chat.setup(opts)
    --         local quickChat = function()
    --             local input = vim.fn.input("Quick Chat: ")
    --             if input ~= "" then
    --                 chat.ask(input, { selection = require("CopilotChat.select").buffer })
    --             end
    --         end
    --
    --         vim.keymap.set({ "n", "v" }, "<leader>ccq", quickChat, { desc = "Quick Chat" })
    --     end
    -- },
}
