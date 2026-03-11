return {
	{
		"stevearc/conform.nvim",
		cmd = { "ConformInfo" },
		keys = {
			{
				"<C-f>",
				function()
					require("conform").format({ async = false, lsp_format = "fallback", timeout_ms = 5000 })
				end,
				mode = "n",
				desc = "Format file with conform",
			},
		},
		config = function()
			require("conform").setup({
				formatters_by_ft = {
					lua = { "stylua" },
					-- Conform will run multiple formatters sequentially
					python = { "black" },
					-- Conform will run the first available formatter
					javascript = { "prettierd", "prettier", stop_after_first = true },
					json = { "prettierd", "prettier", stop_after_first = true },
				},
			})
		end,
	},
}
