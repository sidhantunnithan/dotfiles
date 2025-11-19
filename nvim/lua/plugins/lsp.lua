return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{
				"folke/lazydev.nvim",
				ft = "lua", -- only load on lua files
				opts = {
					library = {
						-- See the configuration section for more details
						-- Load luvit types when the `vim.uv` word is found
						{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
					},
				},
			},
		},

		config = function()
			-- Configure diagnostics display
			vim.diagnostic.config({
				virtual_text = true, -- Show diagnostics as virtual text
				signs = true, -- Show signs in the sign column
				underline = true, -- Underline problematic code
				update_in_insert = false, -- Don't update diagnostics while typing
				severity_sort = true, -- Sort by severity
			})

			-- Setup LSP servers using the new vim.lsp.config API (Neovim 0.11+)
			vim.lsp.config.lua_ls = {
				cmd = { "lua-language-server" },
				root_markers = { ".git" },
				settings = {
					Lua = {
						diagnostics = {
							globals = { "vim" }, -- Recognize 'vim' as a global
						},
					},
				},
			}

			-- Enable the LSP server
			vim.lsp.enable("lua_ls")
		end
	}
}
