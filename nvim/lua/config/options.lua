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
-- Paste deliberately never queries the terminal: osc52.paste() writes an OSC 52 *read*
-- request, and tmux answers it by echoing the whole clipboard back as base64 on the
-- pane's stdin. Unconsumed, those bytes render as garbage and are then read as
-- keystrokes, which is how base64 ended up inside the buffer. Return the unnamed
-- register instead -- no outbound query, no inbound burst.
if vim.env.SSH_TTY ~= nil then
  local ok, osc52 = pcall(require, "vim.ui.clipboard.osc52")
  if ok then
    local function paste()
      return vim.split(vim.fn.getreg(""), "\n")
    end
    vim.g.clipboard = {
      name = "OSC 52",
      copy = {
        ["+"] = osc52.copy("+"),
        ["*"] = osc52.copy("*"),
      },
      paste = {
        ["+"] = paste,
        ["*"] = paste,
      },
    }
    -- Note: clipboard is intentionally NOT set to "unnamedplus" so that normal
    -- d/y/x/c stay in Vim's unnamed register. Only explicit "+ maps (see
    -- keymaps.lua) reach the system clipboard, matching local behavior.
  end
end
