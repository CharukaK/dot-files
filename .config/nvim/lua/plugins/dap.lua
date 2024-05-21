return {
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            {
                "rcarriga/nvim-dap-ui",
                dependencies = {
                    { "nvim-neotest/nvim-nio" }
                }

            },
            "leoluz/nvim-dap-go"
        },
        config = function()
            local dap = require("dap")
            local dapui = require("dapui")

            dapui.setup()

            -- Set keymaps to control the debugger
            vim.keymap.set('n', '<F5>', dap.continue)
            vim.keymap.set('n', '<F8>', dap.step_over)
            vim.keymap.set('n', '<F9>', dap.step_into)
            vim.keymap.set('n', '<F10>', dap.step_out)
            vim.keymap.set('n', '<leader>b', dap.toggle_breakpoint)
            vim.keymap.set('n', '<leader>B', function()
                require 'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))
            end)
            vim.keymap.set('n', '<Leader>dl', function() require('dap').run_last() end)

            dap.listeners.before.attach.dapui_config = function()
                dapui.open()
            end
            dap.listeners.before.launch.dapui_config = function()
                dapui.open()
            end
            dap.listeners.before.event_terminated.dapui_config = function()
                dapui.close()
            end
            dap.listeners.before.event_exited.dapui_config = function()
                dapui.close()
            end

            -- go adapter
            require('dap-go').setup({
                dap_configurations = {
                    {
                        type = "go",
                        name = "Attach remote",
                        mode = "remote",
                        request = "attach",
                        -- tell which host and port to connect to
                        connect = {
                            host = "127.0.0.1",
                            port = "8181"
                        }
                    },
                },
                delve = {
                    port = "8181"
                },
            })
        end
    }
}
