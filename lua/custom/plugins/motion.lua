-- flash.nvim: springen naar elk zichtbaar punt met een paar aanslagen.
--
-- Let op de toetskeuze: de gebruikelijke flash-toets is `s`, maar die is hier van
-- mini.surround (kickstart zet `s` op <Nop> als prefix voor sa/sd/sr). Daarom staat de
-- sprong op `S`. Dat kost de Vim-default "regel vervangen", maar die is hetzelfde als `cc`.
--
-- Gratis meegenomen: flash verbetert standaard ook f/F/t/T, zodat die over meerdere regels
-- werken en labels tonen. Daar is geen aparte toets voor nodig.

vim.pack.add { 'https://github.com/folke/flash.nvim' }

require('flash').setup {}

vim.keymap.set({ 'n', 'x', 'o' }, 'S', function() require('flash').jump() end, { desc = 'Flash: springen' })
vim.keymap.set({ 'n', 'x', 'o' }, 'gS', function() require('flash').treesitter() end, { desc = 'Flash: treesitter-selectie' })
vim.keymap.set('o', 'r', function() require('flash').remote() end, { desc = 'Flash: remote (bv. yr<sprong>)' })
vim.keymap.set({ 'o', 'x' }, 'R', function() require('flash').treesitter_search() end, { desc = 'Flash: treesitter zoeken' })
