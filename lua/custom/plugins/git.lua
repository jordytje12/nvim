-- Git: lazygit voor het dagelijkse werk, diffview voor diffs en merge-conflicten.
--
-- Gitsigns (van kickstart) doet alleen hunks in de marge: stagen per hunk, blame, preview.
-- Deze twee vullen aan wat daar niet in zit.

vim.pack.add {
  'https://github.com/nvim-lua/plenary.nvim', -- door lazygit.nvim vereist, staat er al
  'https://github.com/kdheepak/lazygit.nvim',
  'https://github.com/sindrets/diffview.nvim',
}

require('diffview').setup {}

local map = function(lhs, rhs, desc) vim.keymap.set('n', lhs, rhs, { desc = desc }) end

-- lazygit draait in een float; de binary staat al op je PATH via Homebrew.
map('<leader>gg', '<cmd>LazyGit<cr>', '[G]it: lazy[g]it')
map('<leader>gf', '<cmd>LazyGitCurrentFile<cr>', '[G]it: lazygit voor dit [f]ile')

-- diffview: <leader>gd toont je werkmap-diff, <leader>gh de historie van het huidige bestand.
map('<leader>gd', '<cmd>DiffviewOpen<cr>', '[G]it: [d]iff van werkmap')
map('<leader>gh', '<cmd>DiffviewFileHistory %<cr>', '[G]it: [h]istorie van dit bestand')
map('<leader>gH', '<cmd>DiffviewFileHistory<cr>', '[G]it: historie van de repo')
map('<leader>gc', '<cmd>DiffviewClose<cr>', '[G]it: diffview sluiten')
