vim.g.mapleader = " "

vim.keymap.set("n", "<Tab>", "gt") -- switch tabs

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
    local choice = vim.fn.confirm("There are unsaved changes. Save all before closing?", "&Yes\n&No\n&Cancel", 1)
    if choice == 1 then
      vim.cmd("wa | %bd")
    elseif choice == 2 then
      vim.cmd("%bd!")
    end
  else
    vim.cmd("%bd")
  end
end, { desc = "Close all buffers" })
