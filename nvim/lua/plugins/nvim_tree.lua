return {
  'nvim-tree/nvim-tree.lua',
  version = '*',
  lazy = false,
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },

  config = function()
    -- set git highlight colours
    vim.api.nvim_set_hl(0, 'NvimTreeGitNewIcon', { fg = '#a6e3a1' })

    local function my_on_attach(bufnr)
      local api = require 'nvim-tree.api'

      -- default mappings
      api.config.mappings.default_on_attach(bufnr)

      -- custom mappings
      vim.keymap.set('n', '<leader>e', api.tree.toggle, {
        desc = 'toggle explorer',
        noremap = true,
      })
    end

    require('nvim-tree').setup {
      on_attach = my_on_attach,
      renderer = {
        icons = {
          glyphs = {
            git = {
              unstaged = '✗',
              staged = '✓',
              unmerged = '',
              renamed = '➜',
              untracked = 'U',
              deleted = '',
              ignored = '◌',
            },
          },
        },
      },
    }
  end,
}
