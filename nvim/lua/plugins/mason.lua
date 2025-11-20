return {
	{
		"mason-org/mason.nvim",
		opts = {},
		config = function()
			vim.diagnostic.config({ virtual_text = true })
            require("mason").setup()
		end,
	},
	{
		"neovim/nvim-lspconfig",
		config = function()
		end,
	},
	{
		"mason-org/mason-lspconfig.nvim",
		opts = {},
		dependencies = {
			{ "mason-org/mason.nvim", opts = {} },
			"neovim/nvim-lspconfig",
		},
	},
}
