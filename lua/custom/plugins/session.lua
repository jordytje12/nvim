-- Sessies per projectmap: open buffers, vensterindeling en cursorposities terug.
--
-- Bewust geen autoload bij opstarten: `nvim` in een map geeft je gewoon het dashboard,
-- je haalt de sessie zelf terug met <leader>ps. Anders krijg je bij elke `nvim <bestand>`
-- een halve oude sessie overheen.

vim.pack.add { 'https://github.com/folke/persistence.nvim' }

require('persistence').setup {}

local map = function(lhs, rhs, desc) vim.keymap.set('n', lhs, rhs, { desc = desc }) end

map('<leader>ps', function() require('persistence').load() end, '[P]roject: sessie van deze map')
map('<leader>pl', function() require('persistence').load { last = true } end, '[P]roject: [l]aatste sessie')
map('<leader>pd', function() require('persistence').stop() end, '[P]roject: deze sessie niet opslaan')
