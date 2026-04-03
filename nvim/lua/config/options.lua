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

-- Clipboard: use OSC52 over SSH so yanks can cross remote tmux -> local tmux -> terminal.
if vim.env.SSH_TTY ~= nil then
  local ok, osc52 = pcall(require, "vim.ui.clipboard.osc52")
  if ok then
    vim.g.clipboard = {
      name = "OSC 52",
      copy = {
        ["+"] = osc52.copy("+"),
        ["*"] = osc52.copy("*"),
      },
      paste = {
        ["+"] = osc52.paste("+"),
        ["*"] = osc52.paste("*"),
      },
    }
    vim.opt.clipboard = "unnamedplus"
  end
end
