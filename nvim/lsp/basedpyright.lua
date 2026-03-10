---@brief
---
--- https://detachhead.github.io/basedpyright
---
--- `basedpyright`, a static type checker and language server for python

--- Scan venv site-packages for PEP 660 editable installs (setuptools finder style)
--- and return their source directories so basedpyright can resolve them.
local function get_editable_extra_paths(root_dir)
	local paths = {}
	local site_packages = vim.fn.glob(root_dir .. "/.venv/lib/python*/site-packages", true, true)
	if #site_packages == 0 then
		return paths
	end
	local sp = site_packages[1]
	local finders = vim.fn.glob(sp .. "/__editable__*_finder.py", true, true)
	for _, finder_file in ipairs(finders) do
		for line in io.lines(finder_file) do
			if line:match("^MAPPING") then
				for _, mapped_path in line:gmatch("'([^']+)'%s*:%s*'([^']+)'") do
					if vim.fn.isdirectory(mapped_path) == 1 then
						local parent = vim.fn.fnamemodify(mapped_path, ":h")
						if not vim.tbl_contains(paths, parent) then
							table.insert(paths, parent)
						end
					end
				end
				break
			end
		end
	end
	return paths
end

local function set_python_path(command)
	local path = command.args
	local clients = vim.lsp.get_clients({
		bufnr = vim.api.nvim_get_current_buf(),
		name = "basedpyright",
	})
	for _, client in ipairs(clients) do
		if client.settings then
			---@diagnostic disable-next-line: param-type-mismatch
			client.settings.python = vim.tbl_deep_extend("force", client.settings.python or {}, { pythonPath = path })
		else
			client.config.settings =
				vim.tbl_deep_extend("force", client.config.settings, { python = { pythonPath = path } })
		end
		client:notify("workspace/didChangeConfiguration", { settings = nil })
	end
end

---@type vim.lsp.Config
return {
	cmd = { "basedpyright-langserver", "--stdio" },
	filetypes = { "python" },
	root_dir = function(bufnr, on_dir)
		on_dir(vim.fn.getcwd())
	end,
	capabilities = {
		workspace = {
			didChangeWatchedFiles = {
				dynamicRegistration = false,
			},
		},
	},
	settings = {
		basedpyright = {
			analysis = {
				autoSearchPaths = true,
				useLibraryCodeForTypes = true,
				diagnosticMode = "openFilesOnly",
				typeCheckingMode = "standard",
				diagnosticSeverityOverrides = {
					reportUnknownMemberType = false,
					reportUnknownArgumentType = false,
					reportUnknownVariableType = false,
					reportUnknownParameterType = false,
					reportUnknownLambdaType = false,
				},
			},
		},
	},
	on_attach = function(client, bufnr)
		local root_dir = client.config.root_dir or vim.fn.getcwd()
		local venv = root_dir .. "/.venv/bin/python"
		if vim.fn.executable(venv) == 1 then
			local extra_paths = get_editable_extra_paths(root_dir)

			-- pyrightconfig.json extraPaths overrides LSP extraPaths, so if it
			-- exists we must patch it on disk to include editable-install paths.
			local pyright_cfg = root_dir .. "/pyrightconfig.json"
			if vim.fn.filereadable(pyright_cfg) == 1 then
				local ok, config = pcall(vim.fn.json_decode, vim.fn.readfile(pyright_cfg))
				if ok and config then
					local existing = config.extraPaths or {}
					local changed = false
					for _, p in ipairs(extra_paths) do
						if not vim.tbl_contains(existing, p) then
							table.insert(existing, p)
							changed = true
						end
					end
					if changed then
						config.extraPaths = existing
						local json = vim.fn.system({ "python3", "-m", "json.tool" }, vim.fn.json_encode(config))
						vim.fn.writefile(vim.split(json, "\n", { trimempty = true }), pyright_cfg)
					end
					extra_paths = existing
				end
			end

			client.settings = vim.tbl_deep_extend("force", client.settings or client.config.settings, {
				python = { pythonPath = venv },
				basedpyright = { analysis = { extraPaths = extra_paths } },
			})
			client:notify("workspace/didChangeConfiguration", { settings = nil })
		end

		vim.api.nvim_buf_create_user_command(bufnr, "LspPyrightOrganizeImports", function()
			local params = {
				command = "basedpyright.organizeimports",
				arguments = { vim.uri_from_bufnr(bufnr) },
			}

			-- Using client.request() directly because "basedpyright.organizeimports" is private
			-- (not advertised via capabilities), which client:exec_cmd() refuses to call.
			-- https://github.com/neovim/neovim/blob/c333d64663d3b6e0dd9aa440e433d346af4a3d81/runtime/lua/vim/lsp/client.lua#L1024-L1030
			---@diagnostic disable-next-line: param-type-mismatch
			client.request("workspace/executeCommand", params, nil, bufnr)
		end, {
			desc = "Organize Imports",
		})

		vim.api.nvim_buf_create_user_command(bufnr, "LspPyrightSetPythonPath", set_python_path, {
			desc = "Reconfigure basedpyright with the provided python path",
			nargs = 1,
			complete = "file",
		})
	end,
}
