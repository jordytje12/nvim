-- smear-cursor: geeft de cursor een uitsmerend spoor bij het springen.
--
-- Let op de modulenaam: de repo heet smear-cursor.nvim, maar je require't `smear_cursor`
-- met een underscore.

vim.pack.add { { src = 'https://github.com/sphamba/smear-cursor.nvim', version = vim.version.range '*' } }

require('smear_cursor').setup {
  -- Allemaal standaardwaarden, hier expliciet zodat je ze kunt uitzetten zonder zoeken.
  smear_between_buffers = true,
  smear_between_neighbor_lines = true,
  scroll_buffer_space = true,
  smear_insert_mode = true,

  -- Uit laten staan tenzij je terminal-font legacy computing symbols heeft (bv. Cascadia
  -- Code). Zonder die glyphs geeft `true` blokjes in plaats van een vloeiend spoor.
  legacy_computing_symbols_support = false,
}

-- De plugin registreert zelf :SmearCursorToggle; dit is dezelfde schakelaar op een toets.
vim.keymap.set('n', '<leader>ts', '<cmd>SmearCursorToggle<cr>', { desc = '[T]oggle [s]mear cursor' })
