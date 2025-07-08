return {
    "christoomey/vim-tmux-navigator",
    cmd = {
        "TmuxNavigateLeft",
        "TmuxNavigateDown",
        "TmuxNavigateUp",
        "TmuxNavigateRight",
        "TmuxNavigatePrevious",
        "TmuxNavigatorProcessList",
    },
    keys = {
        { "<M-h>",  "<cmd>TmuxNavigateLeft<cr>" },
        { "<M-j>",  "<cmd>TmuxNavigateDown<cr>" },
        { "<M-k>",  "<cmd>TmuxNavigateUp<cr>" },
        { "<M-l>",  "<cmd>TmuxNavigateRight<cr>" },
        { "<M-\\>", "<cmd>TmuxNavigatePrevious<cr>" },
        -- { "<c-h>",  "<cmd><C-U>TmuxNavigateLeft<cr>" },
        -- { "<c-j>",  "<cmd><C-U>TmuxNavigateDown<cr>" },
        -- { "<c-k>",  "<cmd><C-U>TmuxNavigateUp<cr>" },
        -- { "<c-l>",  "<cmd><C-U>TmuxNavigateRight<cr>" },
        -- { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
    },
}
