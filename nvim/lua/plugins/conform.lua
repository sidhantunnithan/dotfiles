return {
    "stevearc/conform.nvim",
    opts = {},
    config = function()
        require("conform").setup({
            formatters_by_ft = {
                lua = { "stylua" },
                -- Conform will run multiple formatters sequentially
                python = { "isort", "black" },
                json = { "json-lsp"},
            },

            formatters = {
                stylua = {
                    prepend_args = { "--indent-type", "Spaces" },
                },
            },

            -- keybindings
            vim.keymap.set("", "<leader>f", function()
                require("conform").format({ async = true, lsp_fallback = true })
            end),
        })
    end,
}
