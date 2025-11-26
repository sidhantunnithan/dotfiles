return {
	"mason-org/mason.nvim",
	opts = {
		ui = {
			icons = {
				package_installed = "✓",
				package_pending = "➜",
				package_uninstalled = "✗",
			},
		},
	},
	config = function()
		vim.diagnostic.config({
			virtual_text = true,
			update_in_insert = true,
			underline = true,
		})
	end,
}
