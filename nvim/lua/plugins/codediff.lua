return {
	"esmuellert/codediff.nvim",
	cmd = "CodeDiff",
	keys = {
		{ "<leader>gd", "<cmd>CodeDiff<cr>", desc = "Git diff (side-by-side)" },
		{ "<leader>gb", "<cmd>CodeDiff main...<cr>", desc = "Git diff vs main (PR-style)" },
	},
	opts = {
		diff = {
			-- Explicit rather than relying on the upstream default, which could change.
			-- Toggle to the unified/inline layout at runtime with `t` inside the view.
			layout = "side-by-side",
			original_position = "left", -- old on the left, new on the right, as in VSCode
		},
	},
}
