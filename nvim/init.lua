require("config.options")
require("config.lazy")
require("config.keymaps")
require("config.autocmds")

local lsp_configs = {}

for _, f in pairs(vim.api.nvim_get_runtime_file("lsp/*.lua", true)) do
	local server_name = vim.fn.fnamemodify(f, ":t:r")
	table.insert(lsp_configs, server_name)
end

vim.lsp.enable(lsp_configs)

-- LSP Keybindings
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
	callback = function(event)
		local bufnr = event.buf
		local client = vim.lsp.get_client_by_id(event.data.client_id)

		-- Helper function for setting keymaps
		local map = function(mode, lhs, rhs, opts)
			opts = opts or {}
			opts.buffer = bufnr
			vim.keymap.set(mode, lhs, rhs, opts)
		end

		-- Navigation
		map("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
		map("n", "gD", vim.lsp.buf.declaration, { desc = "Go to declaration" })
		map("n", "gi", vim.lsp.buf.implementation, { desc = "Go to implementation" })
		map("n", "go", vim.lsp.buf.type_definition, { desc = "Go to type definition" })
		map("n", "gr", vim.lsp.buf.references, { desc = "Show references" })
		map("n", "gs", vim.lsp.buf.signature_help, { desc = "Show signature help" })

		-- Documentation
		map("n", "K", vim.lsp.buf.hover, { desc = "Hover documentation" })
		map("i", "<C-k>", vim.lsp.buf.signature_help, { desc = "Signature help" })

		-- Code actions & refactoring
		map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
		map("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })

		-- Formatting
		if client and client.supports_method("textDocument/formatting") then
			map("n", "<leader>f", function()
				vim.lsp.buf.format({ async = true })
			end, { desc = "Format buffer" })
		end

		-- Diagnostics
		map("n", "gl", vim.diagnostic.open_float, { desc = "Show line diagnostics" })
		map("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
		map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
		map("n", "[e", function()
			vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
		end, { desc = "Previous error" })
		map("n", "]e", function()
			vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
		end, { desc = "Next error" })
		map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Set loclist" })

		-- Workspace management
		map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, { desc = "Add workspace folder" })
		map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, { desc = "Remove workspace folder" })
		map("n", "<leader>wl", function()
			print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
		end, { desc = "List workspace folders" })

		-- Enable inlay hints if supported
		if client and client.supports_method("textDocument/inlayHint") then
			vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
		end

		-- Enable completion
		vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"
	end,
})
