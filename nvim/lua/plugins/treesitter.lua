return {
		{
			"nvim-treesitter/nvim-treesitter",
			branch = 'master',
			lazy = false,
			build = ":TSUpdate",
			config = function()
				require'nvim-treesitter.configs'.setup {
					  indent = {
					    enable = true
					  },
					ensure_installed = { "c", "lua", "python", "cpp", "csv", "comment", "css", "html", "dockerfile", "go", "javascript", "typescript", "json", "yaml", "latex", "nginx", "rust", "vim", "vimdoc", "query", "markdown", "markdown_inline" },
					auto_install = false,
					highlight = {
						enable = true,
						disable = function(lang, buf)
							local max_filesize = 100 * 1024 -- 100 KB
							local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
							if ok and stats and stats.size > max_filesize then
								return true
							end
						end,
						},
					additional_vim_regex_highlighting = false,
				}
			end
		}
}
