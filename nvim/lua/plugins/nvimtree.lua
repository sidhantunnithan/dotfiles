return {
	"nvim-tree/nvim-tree.lua",
	version = "*",
	lazy = false,
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		local HEIGHT_RATIO = 0.8
		local WIDTH_RATIO = 0.5
		local api = require("nvim-tree.api")

		-- custom keybinding functions
		-- reference https://github.com/nvim-tree/nvim-tree.lua/wiki/Recipes#h-j-k-l-style-navigation-and-editing
		local function edit_or_open()
			local node = api.tree.get_node_under_cursor()

			if node.nodes ~= nil then
				-- expand or collapse folder
				api.node.open.edit()
			else
				-- open file
				api.node.open.edit()
				-- Close the tree if file was opened
				api.tree.close()
			end
		end

		-- open as vsplit on current node
		local function vsplit_preview()
			local node = api.tree.get_node_under_cursor()

			if node.nodes ~= nil then
				-- expand or collapse folder
				api.node.open.edit()
			else
				-- open file as vsplit
				api.node.open.vertical()
			end

			-- Finally refocus on tree if it was lost
			api.tree.focus()
		end

		-- on_attach function for nvim-tree keymaps
		local function on_attach(bufnr)
			-- Load default keybindings first
			api.config.mappings.default_on_attach(bufnr)

			local function opts(desc)
				return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
			end

			-- Override with custom keybindings
			vim.keymap.set("n", "l", edit_or_open, opts("Edit Or Open"))
			vim.keymap.set("n", "L", vsplit_preview, opts("Vsplit Preview"))
			vim.keymap.set("n", "h", api.node.navigate.parent_close, opts("Close Directory"))
			vim.keymap.set("n", "H", api.tree.collapse_all, opts("Collapse All"))
		end

		-- floating nvim tree
		-- reference https://github.com/nvim-tree/nvim-tree.lua/wiki/Recipes#center-a-floating-nvim-tree-window
		require("nvim-tree").setup({
			update_focused_file = {
				enable = true,
			},
			view = {
				float = {
					enable = true,
					open_win_config = function()
						local screen_w = vim.opt.columns:get()
						local screen_h = vim.opt.lines:get() - vim.opt.cmdheight:get()
						local window_w = screen_w * WIDTH_RATIO
						local window_h = screen_h * HEIGHT_RATIO
						local window_w_int = math.floor(window_w)
						local window_h_int = math.floor(window_h)
						local center_x = (screen_w - window_w) / 2
						local center_y = ((vim.opt.lines:get() - window_h) / 2) - vim.opt.cmdheight:get()
						return {
							border = "rounded",
							relative = "editor",
							row = center_y,
							col = center_x,
							width = window_w_int,
							height = window_h_int,
						}
					end,
				},
				width = function()
					return math.floor(vim.opt.columns:get() * WIDTH_RATIO)
				end,
			},
			on_attach = on_attach,
		})

		vim.api.nvim_create_augroup("NvimTreeResize", {
			clear = true,
		})

		vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
			group = "NvimTreeResize",
			callback = function()
				-- Get the nvim-tree window ID
				local winid = api.tree.winid()
				if winid then
					api.tree.reload()
				end
			end,
		})

		-- global toggle keymap
		vim.api.nvim_set_keymap("n", "<C-h>", ":NvimTreeToggle<cr>", { silent = true, noremap = true })
	end,
}
