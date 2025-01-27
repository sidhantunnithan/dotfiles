vim.g.have_nerd_font = true -- add support for nerd fonts
vim.opt.number = true -- make line numbers default
vim.opt.relativenumber = true -- enable relative numbering

vim.opt.tabstop = 4 -- A TAB character looks like 4 spaces
vim.opt.expandtab = true -- Pressing the TAB key will insert spaces instead of a TAB character
vim.opt.softtabstop = 4 -- Number of spaces inserted instead of a TAB character
vim.opt.shiftwidth = 4 -- Number of spaces inserted when indenting
vim.opt.smartindent = true

vim.opt.mouse = 'a' -- enable mouse mode

-- sync clipboard between OS and Neovim
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

vim.opt.breakindent = true -- enable break indent

vim.opt.undofile = true -- save undo history

vim.opt.ignorecase = true -- ignore case when searching
vim.opt.smartcase = true -- match case if upper case in search term

vim.opt.signcolumn = 'yes' -- keep sign colunm on by default

vim.opt.updatetime = 250 -- wait time in ms for stuff like lsp hover / plugin updates
vim.opt.timeoutlen = 300 -- wait time for key combinations to be pressed before getting cancelled

-- configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- configure treatment of invisible characters
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

vim.opt.inccommand = 'split' -- preview substitutions in real time

vim.opt.cursorline = true -- show which line your cursor is on

vim.opt.scrolloff = 10 -- minimal number of screen lines to keep above and below the cursor

-- highlight when yanking text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})
