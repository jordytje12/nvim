-- Next.js / React: tags, template strings, JSX-comments en JSON-schemas.

vim.pack.add {
  'https://github.com/b0o/SchemaStore.nvim',
  'https://github.com/windwp/nvim-ts-autotag',
  'https://github.com/axelvc/template-string.nvim',
  'https://github.com/JoosepAlviste/nvim-ts-context-commentstring',
  -- De catgoose-fork, niet de oude NvChad-versie: die wordt onderhouden en kan tailwind.
  'https://github.com/catgoose/nvim-colorizer.lua',
}

-- tsconfig.json, package.json, eslintrc, etc. SECTION 6 zet jsonls al aan met een lege
-- config; vim.lsp.config merget deze settings daar overheen voordat de client attacht.
vim.lsp.config('jsonls', {
  settings = {
    json = {
      schemas = require('schemastore').json.schemas(),
      validate = { enable = true },
    },
  },
})

-- Auto close/rename JSX & HTML tags
require('nvim-ts-autotag').setup {
  opts = {
    enable_close = true,
    enable_rename = true,
    enable_close_on_slash = true,
  },
}

-- 'foo' + bar -> `foo${bar}` zodra je een interpolatie typt
require('template-string').setup {}

-- Kleuren inline tonen. `tailwind = 'both'` pakt zowel de klassen die het zelf herkent
-- als de kleuren die de tailwind-LSP doorgeeft, dus ook je eigen theme-kleuren.
require('colorizer').setup {
  filetypes = { 'css', 'scss', 'sass', 'less', 'html', 'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'blade', 'php', 'lua' },
  user_default_options = {
    tailwind = 'both',
    css = true,
    mode = 'virtualtext',
    virtualtext = '󱓻',
  },
}

-- Correcte JSX comment style ({/* */} in plaats van //).
-- enable_autocmd blijft aan: kickstart gebruikt geen mini.comment, dus `gc` is Neovim's
-- ingebouwde commenting en die leest simpelweg 'commentstring'. De CursorHold-autocmd
-- van deze plugin houdt die per cursorpositie bij.
vim.g.skip_ts_context_commentstring_module = true
require('ts_context_commentstring').setup {
  enable_autocmd = true,
}
