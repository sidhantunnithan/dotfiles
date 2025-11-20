-- Disable Netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.termguicolors = true

-- Editor settings
vim.opt.number = true -- show line numbers
vim.opt.relativenumber = true -- show relative line number
vim.opt.tabstop = 4 -- set tabstop
vim.opt.softtabstop = -1 -- length to use when editing text (eg. TAB and BS keys)(0 for ‘tabstop’, -1 for ‘shiftwidth’)
vim.opt.shiftwidth = 0 -- length to use when shifting text (eg. <<, >> and == commands) (0 for ‘tabstop’)
vim.opt.expandtab = true -- if set, only insert spaces; otherwise insert \t and complete with spaces
vim.opt.autoindent = true -- reproduce the indentation of the previous line
vim.opt.smartindent = true -- try to be smart (increase the indenting level after ‘{’ decrease it after ‘}’, and so on)
vim.opt.hlsearch = false -- disable highlights results from your previous search
