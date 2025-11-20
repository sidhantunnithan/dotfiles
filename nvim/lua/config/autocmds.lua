-- Auto-reposition help, man, and fugitive windows to the right
-- reference : https://www.reddit.com/r/vim/comments/j5ngwx/automatically_opening_help_in_vertical_split/
vim.cmd([[
  au WinNew * au BufEnter * ++once
    \ if (&bt ==? 'help' || &ft ==? 'man' || &ft ==? 'fugitive')
    \ && winwidth(winnr('#')) >= 80 | wincmd L | endif
]])
