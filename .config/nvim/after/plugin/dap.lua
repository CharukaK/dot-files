local dap = require("dap")

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

require("dapui").setup()

local dapui = require("dapui")

dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open({})
end
dap.listeners.before.event_terminated["dapui_config"] = function()
  dapui.close({})
end
dap.listeners.before.event_exited["dapui_config"] = function()
  dapui.close({})
end

vim.keymap.set('n', '<leader>ui', require 'dapui'.toggle)
vim.keymap.set('n', '<leader>ui', require 'dapui'.toggle)

vim.fn.sign_define('DapBreakpoint', { text = '🔴', texthl = '', linehl = '', numhl = '' })
vim.fn.sign_define('DapStopped', { text = '▶️', texthl = '', linehl = '', numhl = '' })
vim.fn.sign_define('DapBreakpointRejected', { text = '⭕', texthl = 'LspDiagnosticsSignHint', linehl = '', numhl = '' })

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
