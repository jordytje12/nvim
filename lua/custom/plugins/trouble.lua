-- Trouble: betere diagnostics-lijst dan de quickfix.

vim.pack.add { 'https://github.com/folke/trouble.nvim' }

require('trouble').setup {}

local map = function(lhs, rhs, desc) vim.keymap.set('n', lhs, rhs, { desc = desc }) end

map('<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', 'Diagnostics (Trouble)')
map('<leader>xX', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', 'Buffer Diagnostics (Trouble)')
map('<leader>xl', '<cmd>Trouble lsp toggle focus=false win.position=right<cr>', 'LSP Definitions / References (Trouble)')
map('<leader>xq', '<cmd>Trouble qflist toggle<cr>', 'Quickfix List (Trouble)')

map(']t', function() require('trouble').next { skip_groups = true, jump = true } end, 'Next trouble item')
map('[t', function() require('trouble').prev { skip_groups = true, jump = true } end, 'Previous trouble item')
