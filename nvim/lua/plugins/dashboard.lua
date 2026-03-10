return {
	"nvimdev/dashboard-nvim",
	event = "VimEnter",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	opts = {
		theme = "hyper",
		config = {
			week_header = {
				enable = true,
			},
			shortcut = {
				{ desc = "󰊳 Update", group = "@property", action = "Lazy update", key = "u" },
				{ icon = " ", icon_hl = "@variable", desc = "Files", group = "Label", action = "Telescope find_files", key = "f" },
				{ desc = " Grep", group = "DiagnosticHint", action = "Telescope live_grep", key = "g" },
				{ desc = " Recent", group = "Number", action = "Telescope oldfiles", key = "r" },
			},
			packages = { enable = true },
			project = { enable = true, limit = 8, icon = " ", label = "", action = "Telescope find_files cwd=" },
			mru = { limit = 10, icon = " ", label = "", cwd_only = false },
			footer = {},
		},
	},
}
