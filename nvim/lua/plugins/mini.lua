return {
	"nvim-mini/mini.nvim",
	version = false,
	config = function()
		require("mini.pairs").setup()
		require("mini.comment").setup({
			-- Module mappings. Use `''` (empty string) to disable one.
			mappings = {
				-- Toggle comment (like `gcip` - comment inner paragraph) for both
				-- Normal and Visual modes
                comment_line = "gcc",
                comment_visual = "gcc",
			},
		})
	end,
}
