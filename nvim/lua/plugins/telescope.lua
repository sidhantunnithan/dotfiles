return {
	"nvim-telescope/telescope.nvim",
	tag = "v0.1.9",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
	},
	config = function()
		local builtin = require("telescope.builtin")
		local actions = require("telescope.actions")
		local action_state = require("telescope.actions.state")

		-- Custom action to open in new tab or switch to existing tab
		local function open_or_switch_to_tab(prompt_bufnr)
			local entry = action_state.get_selected_entry()
			if not entry then
				return
			end

			-- Get the file path
			local filepath = entry.path or entry.filename
			if not filepath then
				return
			end

			-- Get absolute path
			filepath = vim.fn.fnamemodify(filepath, ":p")

			-- Close telescope
			actions.close(prompt_bufnr)

			-- Check if current buffer is empty or replaceable
			local current_buf = vim.api.nvim_get_current_buf()
			local bufname = vim.fn.bufname(current_buf)
			local buftype = vim.bo[current_buf].buftype
			local is_directory = vim.fn.isdirectory(bufname) == 1
			local is_modified = vim.bo[current_buf].modified
			local line_count = vim.api.nvim_buf_line_count(current_buf)

			-- Buffer is empty if:
			-- 1. Not modified AND
			-- 2. (Has no name OR is a directory OR is special buffer) AND
			-- 3. Has only empty lines
			local is_empty = false
			if not is_modified then
				if bufname == "" or is_directory or buftype ~= "" then
					-- Check if buffer only has empty content
					local all_empty = true
					for i = 1, line_count do
						if vim.fn.getline(i) ~= "" then
							all_empty = false
							break
						end
					end
					is_empty = all_empty
				end
			end

			-- Check if file is already open in any tab
			local found_tab = nil
			local found_win = nil

			for tabnr = 1, vim.fn.tabpagenr("$") do
				local wins = vim.fn.tabpagebuflist(tabnr)
				for winnr, bufnr in ipairs(wins) do
					local bufpath = vim.fn.fnamemodify(vim.fn.bufname(bufnr), ":p")
					if bufpath == filepath then
						found_tab = tabnr
						found_win = winnr
						break
					end
				end
				if found_tab then
					break
				end
			end

			if found_tab then
				-- Switch to the existing tab and window
				vim.cmd(found_tab .. "tabnext")
				vim.cmd(found_win .. "wincmd w")
			elseif is_empty then
				-- Open in current buffer if it's empty
				vim.cmd("edit " .. vim.fn.fnameescape(filepath))
			else
				-- Open in a new tab
				vim.cmd("tabnew " .. vim.fn.fnameescape(filepath))
			end
		end

		local picker_opts = {
			theme = "ivy",
			mappings = {
				n = {
					["<CR>"] = open_or_switch_to_tab,
				},
				i = {
					["<CR>"] = open_or_switch_to_tab,
				},
			},
		}

		require("telescope").setup({
			pickers = {
				find_files = picker_opts,
				live_grep = picker_opts,
			},
			extensions = {
				fzf = {
					fuzzy = true,
					override_generic_sorter = true,
					override_file_sorter = true,
					case_mode = "smart_case", -- or "ignore_case" or "respect_case"
				},
			},
		})

		vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
		vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
		vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
		vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
	end,
}
