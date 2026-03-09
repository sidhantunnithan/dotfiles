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
vim.opt.signcolumn = "yes" -- try to be smart (increase the indenting level after ‘{’ decrease it after ‘}’, and so on)
vim.opt.hlsearch = false -- disable highlights results from your previous search

-- Clipboard: use OSC 52 explicitly so it works over SSH through tmux.
-- On local (macOS), SSH_TTY is unset so we skip OSC 52 and let nvim use pbcopy via unnamedplus.
if vim.env.SSH_TTY ~= nil then
  vim.g.clipboard = {
    name = 'OSC 52',
    copy = {
      ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
      ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
    },
    paste = {
      ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
      ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
    },
  }
end
vim.opt.clipboard = 'unnamedplus'
