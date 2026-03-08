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
	config = function(_, opts)
		require("mason").setup(opts)
		vim.diagnostic.config({
			virtual_text = true,
			update_in_insert = true,
			underline = true,
		})
		local registry = require("mason-registry")
		registry.refresh(function()
			for _, pkg_name in ipairs({ "basedpyright", "black" }) do
				local pkg = registry.get_package(pkg_name)
				if not pkg:is_installed() then
					pkg:install()
				end
			end
		end)
	end,
}
