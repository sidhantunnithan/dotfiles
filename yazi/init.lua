require("bookmarks"):setup({
	last_directory = { enable = true, persist = false, mode = "dir", key = "`" },
	persist = "all",
	desc_format = "full",
	file_pick_mode = "parent",
	show_keys = true,
	notify = {
		enable = false,
	},
})

require("full-border"):setup()
