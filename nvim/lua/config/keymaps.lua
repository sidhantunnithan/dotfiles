vim.g.mapleader = " "

vim.keymap.set("n", "<Tab>", "gt") -- switch tabs

-- Using <leader> + number (1, 2, ... 9) to switch tab
for i = 1, 9, 1 do
	vim.keymap.set("n", "<leader>" .. i, i .. "gt", {})
end
vim.keymap.set("n", "<leader>0", ":tablast<cr>", {})
