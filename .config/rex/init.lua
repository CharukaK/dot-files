-- Load configuration by functionality.
local config_dir = rex.config_dir or os.getenv("REX_CONFIG_DIR") or os.getenv("HOME") .. "/.config/rex"

dofile(config_dir .. "/session_management.lua")
require("rex-navigator").setup()
