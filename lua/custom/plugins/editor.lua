-- Editor-gedrag zonder plugins: de omgeving die `custom.goto_file` nodig heeft,
-- plus auto-reload van buffers die buiten Neovim om veranderen.

local goto_file = require 'custom.goto_file'

-- Zonder dit pakt gf op `@/components/Header` alleen `/components/Header`: de kale `@`
-- in 'isfname' betekent "alle alfabetische tekens", niet het teken zelf.
-- 'isfname' is global-only, dus dit kan niet per filetype.
vim.opt.isfname:append '@-@'

-- ---------- lange regels ----------
--
-- 'wrap' staat al aan (Neovim-default), dus regels lopen niet het scherm uit. Wat ontbrak:
-- zonder 'linebreak' breekt hij middenin een woord af, en zonder 'showbreak' zie je niet
-- of je naar een vervolgregel kijkt of naar een nieuwe regel. 'breakindent' (van kickstart)
-- zorgt dat de vervolgregel onder de inspringing van het origineel blijft staan.
vim.o.linebreak = true
vim.o.showbreak = '↪ '

-- De kolom waar je formatter straks toch gaat afbreken, zichtbaar terwijl je typt.
-- Waarden komen overeen met wat de formatters in SECTION 7 daadwerkelijk doen, zodat de
-- streep niet liegt. textwidth blijft 0: de formatter breekt af bij :w, niet je toetsenbord.
local KOLOMBREEDTE = {
  -- prettier, printWidth 80
  javascript = 80,
  javascriptreact = 80,
  typescript = 80,
  typescriptreact = 80,
  css = 80,
  scss = 80,
  html = 80,
  json = 80,
  jsonc = 80,
  graphql = 80,
  markdown = 80,
  -- ruff, line-length 88
  python = 88,
  -- clang-format, LLVM-stijl ColumnLimit 80
  c = 80,
  cpp = 80,
  -- pint/PSR-12 kent geen harde limiet; 120 als zachte hint
  php = 120,
  blade = 120,
  lua = 160, -- stylua: column_width uit ~/.config/nvim/.stylua.toml
}

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('UserKolomBreedte', { clear = true }),
  callback = function(args)
    local breedte = KOLOMBREEDTE[vim.bo[args.buf].filetype]
    if breedte then vim.wo.colorcolumn = tostring(breedte) end
  end,
})

-- Soms wil je wrap juist uit: brede tabellen, logs, minified bestanden. Dan schuift het
-- scherm horizontaal mee, en houdt sidescrolloff wat context naast de cursor.
vim.o.sidescrolloff = 8

vim.keymap.set('n', '<leader>tw', function()
  vim.wo.wrap = not vim.wo.wrap
  vim.notify('wrap ' .. (vim.wo.wrap and 'aan' or 'uit'))
end, { desc = '[T]oggle [w]rap voor lange regels' })

vim.keymap.set('n', '<leader>tc', function()
  vim.wo.colorcolumn = vim.wo.colorcolumn == '' and tostring(KOLOMBREEDTE[vim.bo.filetype] or 80) or ''
  vim.notify('kolomstreep ' .. (vim.wo.colorcolumn == '' and 'uit' or 'aan op ' .. vim.wo.colorcolumn))
end, { desc = '[T]oggle [c]olorcolumn' })

-- Slimme gd: LSP-definitie met fallback naar het bestand onder de cursor.
-- Deze globale map dekt buffers zonder LSP; de LspAttach hieronder zet dezelfde functie
-- nog eens buffer-lokaal, omdat kickstart's LspAttach anders een eigen gd overheen legt.
vim.keymap.set('n', 'gd', goto_file.definition, { desc = 'Smart goto definition / file' })

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserSmartGotoDefinition', { clear = true }),
  callback = function(args) vim.keymap.set('n', 'gd', goto_file.definition, { buffer = args.buf, desc = 'LSP definition (smart)' }) end,
})

-- gf: laat `@/x` naar <root>/src/x wijzen en raad extensies, net als de slimme gd
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('UserJsGotoFile', { clear = true }),
  pattern = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'json', 'css', 'scss' },
  callback = function(args)
    local root = goto_file.root(args.buf)
    vim.bo[args.buf].suffixesadd = '.ts,.tsx,.js,.jsx,.mjs,.cjs,.json,.css,.scss'
    vim.bo[args.buf].includeexpr = "v:lua.require'custom.goto_file'.includeexpr(v:fname)"
    vim.bo[args.buf].path = table.concat({ '.', root, vim.fs.joinpath(root, 'src'), '' }, ',')
  end,
})

-- Django templates. Nvim herkent zelf al {% %} en {# in de eerste 40 regels; dit dekt
-- templates zonder Django-tag bovenaan. Gated op manage.py, zodat .html in het Next.js
-- project gewoon html blijft.
vim.filetype.add {
  pattern = {
    ['.*/templates/.*%.html'] = function(_, bufnr)
      if vim.fs.root(bufnr, 'manage.py') then return 'htmldjango' end
    end,
  },
}

-- ---------- uit een terminal komen ----------
--
-- In terminal-invoermodus gaat elke toets naar het programma, dus ook <Esc>. De enige
-- ingebouwde uitgang is <C-\><C-n>, en die typt niet prettig. Dubbel-Esc is makkelijker.
--
-- Bewust dubbel en niet enkel: een enkele <Esc> moet naar het programma blijven gaan,
-- anders sloopt dit lazygit, htop en alles wat Esc zelf gebruikt. Om dezelfde reden slaan
-- we lazygit-terminals helemaal over -- daar navigeer je juist met Esc.
vim.api.nvim_create_autocmd('TermOpen', {
  group = vim.api.nvim_create_augroup('UserTerminalEscape', { clear = true }),
  callback = function(args)
    if vim.api.nvim_buf_get_name(args.buf):lower():find 'lazygit' then return end
    vim.keymap.set('t', '<Esc><Esc>', [[<C-\><C-n>]], { buffer = args.buf, desc = 'Terminal verlaten' })
  end,
})

-- Auto-reload: detect external file changes
vim.o.autoread = true

vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold', 'CursorHoldI' }, {
  group = vim.api.nvim_create_augroup('UserAutoRead', { clear = true }),
  pattern = '*',
  command = "if mode() != 'c' | checktime | endif",
})

vim.api.nvim_create_autocmd('FileChangedShellPost', {
  group = vim.api.nvim_create_augroup('UserFileChangedNotify', { clear = true }),
  pattern = '*',
  callback = function() vim.notify('File changed on disk. Buffer reloaded.', vim.log.levels.WARN) end,
})
