-- Session and tab management.

local config_dir = rex.config_dir or os.getenv("REX_CONFIG_DIR") or os.getenv("HOME") .. "/.config/rex"

rex.action{
  name = "open_sessionizer",
  title = "Open Sessionizer",
  run = function(ctx)
    local result, err = rex.session.new_layer{
      bounds = { 0.15, 0.15, 0.7, 0.7 },
      layout = rex.layout.block{
        flavor = "com.superlogical.terminal.shell",
        options = {
          command = { "/bin/bash", "/Users/charukak/personal/dot-files/custom_scripts/rex-sessionizer.sh" },
          exit = { on_completion = true },
        },
      },
      focus = true,
    }
    if result == nil then error(err, 0) end
  end,
}

rex.bind("ctrl+a>n", "open_sessionizer")
rex.bind("ctrl+a>s", "session.rename")
rex.bind("ctrl+a>t", "client.tab.rename")
