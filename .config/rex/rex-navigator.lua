-- Add this file to ~/.config/rex/ and require("rex-navigator") from init.lua.
-- Each binding handles the key only when its focused terminal is not running Neovim.

local module = {}

local terminal_creator = "com.superlogical.terminal"
local neovim_process_names = {
  nvim = true,
  vim = true,
  view = true,
  ["nvim-qt"] = true,
}

local function terminal_is_neovim(ctx)
  if not ctx.block_id then
    return false
  end

  local process, err = rex.block.call(terminal_creator, "process", {
    block_id = ctx.block_id,
  })
  if err ~= nil or process == nil then
    return false
  end

  local foreground = process.foreground or process
  local command = foreground.name or foreground.path or foreground.command or foreground.comm or foreground.executable or ""
  command = command:lower():match("([^/]+)$") or ""
  return neovim_process_names[command] == true
end

local function bind_navigation_key(key, direction)
  rex.bind(key, function(ctx)
    if terminal_is_neovim(ctx) then
      return false
    end

    local _, err
    if direction == "previous" then
      _, err = rex.session.focus_previous_pane{}
    else
      _, err = rex.session.focus_direction{ direction = direction }
    end
    if err ~= nil then
      error(err, 0)
    end
    return true
  end)
end

function module.setup()
  bind_navigation_key("alt+h", "left")
  bind_navigation_key("alt+j", "down")
  bind_navigation_key("alt+k", "up")
  bind_navigation_key("alt+l", "right")
  bind_navigation_key("alt+\\", "previous")
end

return module
