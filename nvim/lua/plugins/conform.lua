return {
	{
		'stevearc/conform.nvim',
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		config = function()
			require("conform").setup({
				formatters_by_ft = {
					lua = { "stylua" },
					-- Conform will run multiple formatters sequentially
					python = { "black" },
					-- Conform will run the first available formatter
					javascript = { "prettierd", "prettier", stop_after_first = true },
				},
			})

			-- Keymap for formatting with conform
			vim.keymap.set("n", "<leader>f", function()
				require("conform").format({ async = false, lsp_format = "fallback" })
			end, { desc = "Format file with conform" })
		end
	}
}
