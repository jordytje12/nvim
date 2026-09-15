-- Buffer-beheer en de file tree, de dingen die kickstart zelf niet meelevert.
--
-- Kickstart heeft geen enkele buffer-keymap: alleen <leader><leader> (telescope-lijst).
-- Hieronder staat wat NvChad's tabufline deed.

local map = function(lhs, rhs, desc) vim.keymap.set('n', lhs, rhs, { desc = desc }) end

-- ---------- file tree ----------
-- Kickstart mapt alleen `\` (Neotree reveal). <leader>e togglet en onthult het huidige bestand.
map('<leader>e', '<cmd>Neotree toggle reveal<cr>', 'File [e]xplorer')

-- ---------- bufferlijst bovenin ----------
-- Bewust bufferline.nvim en niet mini.tabline: alleen deze kent `offsets`, waarmee de
-- lijst pas begint waar je code begint in plaats van ook over de neo-tree heen te lopen.
--
-- Icons komen van mini.icons: kickstart draait MiniIcons.mock_nvim_web_devicons(), dus
-- bufferline's require('nvim-web-devicons') werkt zonder die plugin echt te installeren.
vim.pack.add { { src = 'https://github.com/akinsho/bufferline.nvim', version = vim.version.range '4.*' } }

require('bufferline').setup {
  options = {
    -- Reserveert ruimte zolang de tree open staat, met de kop erboven.
    offsets = {
      {
        filetype = 'neo-tree',
        text = 'Verkenner',
        text_align = 'left',
        separator = true,
      },
    },
    diagnostics = 'nvim_lsp',
    show_buffer_close_icons = false,
    show_close_icon = false,
    always_show_bufferline = true,

    -- Terminals (CMake-runner, lazygit) horen niet in de bufferlijst: die open en sluit
    -- je met hun eigen toets, en anders schuiven ze mee in de <S-j>/<S-k>-cyclus.
    custom_filter = function(bufnr) return vim.bo[bufnr].buftype ~= 'terminal' end,
  },
}

-- ---------- buffers ----------

--- Sluit een buffer zonder de vensterindeling om te gooien.
--- Een kale :bdelete sluit ook het venster als dat de laatste buffer toonde; daarom zetten
--- we eerst elk venster dat deze buffer toont op een andere buffer.
local function buf_close(force)
  local cur = vim.api.nvim_get_current_buf()

  -- Terminals (bv. de CMake-runner) altijd forceren. Neovim weigert een terminal met een
  -- lopende job te sluiten (E947), en omdat kickstart 'confirm' aanzet wordt die weigering
  -- een ja/nee-dialoog in plaats van een fout. Er valt bij een terminal niets te verliezen,
  -- dus die vraag is alleen maar in de weg.
  if vim.bo[cur].buftype == 'terminal' then force = true end

  if not force and vim.bo[cur].modified then
    vim.notify('Buffer heeft niet-opgeslagen wijzigingen (gebruik <leader>bD)', vim.log.levels.WARN)
    return
  end

  local others = vim.tbl_filter(function(b) return b ~= cur and vim.bo[b].buflisted end, vim.api.nvim_list_bufs())

  local alt = vim.fn.bufnr '#'
  local target = (alt ~= -1 and alt ~= cur and vim.api.nvim_buf_is_valid(alt) and vim.bo[alt].buflisted) and alt or others[1]

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == cur then
      if not target then
        -- laatste buffer: val terug op een lege, anders sluit Neovim het venster
        target = vim.api.nvim_create_buf(true, false)
      end
      vim.api.nvim_win_set_buf(win, target)
    end
  end

  pcall(vim.api.nvim_buf_delete, cur, { force = force })
end

--- Sluit alle andere listed buffers; slaat aangepaste buffers over.
local function buf_close_others()
  local cur = vim.api.nvim_get_current_buf()
  local closed = 0
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if b ~= cur and vim.bo[b].buflisted and not vim.bo[b].modified then
      -- force voor terminals, zie de toelichting in buf_close
      pcall(vim.api.nvim_buf_delete, b, { force = vim.bo[b].buftype == 'terminal' })
      closed = closed + 1
    end
  end
  vim.notify(string.format('%d buffer(s) gesloten', closed), vim.log.levels.INFO)
end

map('<leader>bd', function() buf_close(false) end, '[B]uffer sluiten')
map('<leader>bD', function() buf_close(true) end, '[B]uffer sluiten (forceren)')
map('<leader>bo', buf_close_others, '[B]uffer: andere sluiten')
-- BufferLineCycle* en niet :bnext/:bprevious -- die lopen op buffernummer, wat niet de
-- volgorde is die je bovenin ziet. Zo komt "links" ook echt links uit.
map('<leader>bn', '<cmd>BufferLineCycleNext<cr>', '[B]uffer volgende')
map('<leader>bp', '<cmd>BufferLineCyclePrev<cr>', '[B]uffer vorige')
map('<leader>bb', '<cmd>enew<cr>', '[B]uffer nieuw')
map('<leader>bP', '<cmd>BufferLinePick<cr>', '[B]uffer kiezen met letter')

-- Shift-J / Shift-K wisselen van buffer (links / rechts).
--
-- Let op: dit kost twee Vim-defaults, dus die verhuizen hieronder:
--   J = regels samenvoegen  -> <leader>j
--   K = LSP hover-documentatie -> <leader>k
-- Wil je die defaults terug, gebruik dan <S-h>/<S-l> voor buffers; die zijn ook vrij.
map('<S-j>', '<cmd>BufferLineCyclePrev<cr>', 'Buffer links')
map('<S-k>', '<cmd>BufferLineCycleNext<cr>', 'Buffer rechts')

map('<leader>j', 'J', 'Regels samenvoegen (was J)')
map('<leader>k', function() vim.lsp.buf.hover() end, 'Hover-documentatie (was K)')
