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

			local is_empty = false
			if not is_modified then
				if bufname == "" or is_directory or buftype ~= "" then
					local lines = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)
					is_empty = #lines == 1 and lines[1] == ""
				end
			end

			-- Check if file is already open in any tab
			local found_tab = nil
			local found_win = nil

			for tabnr = 1, vim.fn.tabpagenr("$") do
				local wins = vim.fn.tabpagebuflist(tabnr)
				for winnr, bufnr in ipairs(wins) do
					if vim.api.nvim_buf_get_name(bufnr) == filepath then
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
			defaults = {
				follow = true,
			},
			pickers = {
				find_files = picker_opts,
				live_grep = picker_opts,
			},
			extensions = {
				fzf = {
					fuzzy = true,
					override_generic_sorter = true,
					override_file_sorter = true,
					case_mode = "smart_case",
				},
			},
		})

		require("telescope").load_extension("fzf")

		vim.keymap.set("n", "<leader>ff", function()
			builtin.find_files({ find_command = { "rg", "--files", "--follow", "--hidden" } })
		end, { desc = "Telescope find files" })
		vim.keymap.set("n", "<leader>fg", function()
			builtin.live_grep({
				vimgrep_arguments = {
					"rg", "--color=never", "--no-heading", "--with-filename",
					"--line-number", "--column", "--smart-case", "--hidden", "--follow",
				},
			})
		end, { desc = "Telescope live grep" })
		vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
		vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
	end,
}
