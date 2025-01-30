return {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {--[[ things you want to change go here]]
    },
    config = function()
        require("toggleterm").setup({
            -- set prefix key for terminal
            open_mapping = [[<c-\>]],
            -- set terminal type that will be opened 
            direction = "float",
            -- close the terminal on process exit
            close_on_exit = true,
        })
    end,
}
