return {
	"sindrets/diffview.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	cmd = { "DiffviewOpen", "DiffviewFileHistory" },
	keys = {
		{ "<leader>gd", function()
			local lib = require("diffview.lib")
			if lib.get_current_view() then
				vim.cmd("DiffviewClose")
			else
				vim.cmd("DiffviewOpen")
			end
		end, desc = "Diffview toggle" },
		{ "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview file history" },
	},
	opts = {
		keymaps = {
			view = {
				{ "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
			},
			file_panel = {
				{ "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
			},
			file_history_panel = {
				{ "n", "q", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" } },
			},
		},
		hooks = {
			view_opened = function()
				local ok, api = pcall(require, "nvim-tree.api")
				if ok then
					api.tree.close()
				end
			end,
		},
	},
}
