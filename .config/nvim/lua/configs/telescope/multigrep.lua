local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local make_entry = require "telescope.make_entry"
local conf = require "telescope.config".values

local M = {}

local live_multigrep = function(opts)
    opts = opts or {}
    opts.cwd = opts.cwd or vim.uv.cwd()

    -- Inherit hidden + file_ignore_patterns from the live_grep picker config
    -- so multigrep behaves consistently with the stock live_grep defaults.
    local live_grep_defaults = (require("telescope.config").pickers or {})["live_grep"] or {}
    opts = vim.tbl_deep_extend("keep", opts, live_grep_defaults)

    local finder = finders.new_async_job {
        command_generator = function(prompt)
            local pieces = vim.split(prompt or "", "  ")
            local search_pattern = vim.trim(pieces[1] or "")
            local glob_input     = vim.trim(pieces[2] or "")

            if search_pattern == "" then
                return nil
            end

            local args = { "rg" }

            if opts.hidden then
                table.insert(args, "--hidden")
            end

            table.insert(args, "-e")
            table.insert(args, search_pattern)

            if glob_input ~= "" then
                for _, glob in ipairs(vim.split(glob_input, ",")) do
                    local g = vim.trim(glob)
                    if g ~= "" then
                        table.insert(args, "-g")
                        table.insert(args, g)
                    end
                end
            end

            if opts.additional_args then
                if type(opts.additional_args) == "function" then
                    vim.list_extend(args, opts.additional_args(opts))
                elseif type(opts.additional_args) == "table" then
                    vim.list_extend(args, opts.additional_args)
                end
            end

            return vim.list_extend(args, {
                "--color=never",
                "--no-heading",
                "--with-filename",
                "--line-number",
                "--column",
                "--smart-case",
            })
        end,
        entry_maker = make_entry.gen_from_vimgrep(opts),
        cwd = opts.cwd,
    }

    pickers.new(opts, {
        debounce = 100,
        prompt_title = "Multi Grep  <pattern>  [glob]",
        finder = finder,
        previewer = conf.grep_previewer(opts),
        sorter = require "telescope.sorters".empty(),
    }):find()
end

M.setup = function()
    vim.keymap.set('n', '<leader>sg', live_multigrep, { desc = '[S]earch by [G]rep' })
end

return M
