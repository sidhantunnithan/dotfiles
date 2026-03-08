vim.g.mapleader = " "

vim.keymap.set("n", "<Tab>", "gt") -- switch tabs
vim.keymap.set("n", "<C-t>", ":tabnew<cr>", { desc = "New tab" })

-- Using <leader> + number (1, 2, ... 9) to switch tab
for i = 1, 9, 1 do
	vim.keymap.set("n", "<leader>" .. i, i .. "gt", {})
end
vim.keymap.set("n", "<leader>0", ":tablast<cr>", {})

vim.keymap.set("n", "<leader>x", function()
  if vim.bo.modified then
    local choice = vim.fn.confirm("Save changes before closing?", "&Yes\n&No\n&Cancel", 1)
    if choice == 1 then
      vim.cmd("w | bd")
    elseif choice == 2 then
      vim.cmd("bd!")
    end
  else
    vim.cmd("bd")
  end
end, { desc = "Close buffer" })

vim.keymap.set("n", "<leader>X", function()
  local modified_bufs = vim.tbl_filter(function(buf)
    return vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].modified
  end, vim.api.nvim_list_bufs())

  if #modified_bufs > 0 then
    local choice = vim.fn.confirm("There are unsaved changes. Save all before quitting?", "&Yes\n&No\n&Cancel", 1)
    if choice == 1 then
      vim.cmd("wa | qa")
    elseif choice == 2 then
      vim.cmd("qa!")
    end
  else
    vim.cmd("qa")
  end
end, { desc = "Quit Neovim" })

vim.keymap.set("n", "<leader>o", function()
  local path = vim.fn.input("Open file: ", "", "file")
  if path ~= "" then
    path = vim.fn.expand(path)
    vim.cmd("tabnew " .. vim.fn.fnameescape(path))
  end
end, { desc = "Open file by path" })

vim.keymap.set("n", "<leader>cp", function()
  vim.fn.setreg("+", vim.fn.expand("%:p"))
  vim.notify("Copied: " .. vim.fn.expand("%:p"))
end, { desc = "Copy absolute file path" })
