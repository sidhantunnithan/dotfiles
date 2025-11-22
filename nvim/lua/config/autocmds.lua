-- Auto-reposition help, man, and fugitive windows to the right
-- reference : https://www.reddit.com/r/vim/comments/j5ngwx/automatically_opening_help_in_vertical_split/
vim.cmd([[
  au WinNew * au BufEnter * ++once
    \ if (&bt ==? 'help' || &ft ==? 'man' || &ft ==? 'fugitive')
    \ && winwidth(winnr('#')) >= 80 | wincmd L | endif
]])

-- Quickfix auto-preview: automatically jump to file when moving cursor in quickfix
local qf_preview_ns = vim.api.nvim_create_namespace("qf_preview_highlight")

vim.api.nvim_create_autocmd("FileType", {
	pattern = "qf",
	callback = function()
		vim.api.nvim_create_autocmd("CursorMoved", {
			buffer = 0,
			callback = function()
				-- Get current quickfix entry and open it
				vim.cmd(".cc")

				-- We're now in the target window, get current buffer and line
				local target_buf = vim.api.nvim_get_current_buf()
				local target_line = vim.fn.line(".")

				-- Clear previous highlights from all buffers
				for _, buf in ipairs(vim.api.nvim_list_bufs()) do
					if vim.api.nvim_buf_is_valid(buf) then
						vim.api.nvim_buf_clear_namespace(buf, qf_preview_ns, 0, -1)
					end
				end

				-- Add highlight to current line
				vim.api.nvim_buf_add_highlight(target_buf, qf_preview_ns, "Search", target_line - 1, 0, -1)

				-- Return to quickfix window
				vim.cmd("wincmd p")
			end,
		})
	end,
})

-- Clear quickfix preview highlights when quickfix window closes
vim.api.nvim_create_autocmd("BufWinLeave", {
	callback = function()
		if vim.bo.buftype == "quickfix" then
			-- Clear highlights from all buffers
			for _, buf in ipairs(vim.api.nvim_list_bufs()) do
				if vim.api.nvim_buf_is_valid(buf) then
					vim.api.nvim_buf_clear_namespace(buf, qf_preview_ns, 0, -1)
				end
			end
		end
	end,
})
