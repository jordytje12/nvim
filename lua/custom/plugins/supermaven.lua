-- Supermaven: inline AI-completion.
--
-- Eerste keer: :SupermavenUseFree (of :SupermavenUsePro) om in te loggen.
--
-- Let op: die commando's geven geen enkele feedback. :SupermavenUseFree schrijft alleen een
-- JSON-regel naar de agent ("fails silently" volgens de plugin zelf), en :SupermavenStatus
-- logt op niveau `trace` terwijl de drempel `info` is -- die print dus nooit iets.
-- Gebruik :SupermavenInfo hieronder om te zien wat er echt aan de hand is.
--
-- disable_keymaps staat aan zodat <Tab> vrij blijft: die is van snippet-jumps (LuaSnip /
-- vim.snippet), niet van Supermaven.
--
-- Bewust Ctrl en geen Alt: op macOS stuurt Option standaard een los teken (Alt-f wordt `ƒ`)
-- in plaats van Meta, tenzij je terminal "Option as Meta" aanstaat. Ctrl werkt overal.
-- <C-l>, <C-j> en <C-]> botsen niet met blink.cmp's default preset (<C-y>/<C-e>/<C-n>/<C-p>).

vim.pack.add { 'https://github.com/supermaven-inc/supermaven-nvim' }

local supermaven = require 'supermaven-nvim'
local completion = require 'supermaven-nvim.completion_preview'

supermaven.setup {
  disable_keymaps = true,
  ignore_filetypes = { TelescopePrompt = true, ['neo-tree'] = true },
}

vim.keymap.set('i', '<C-l>', function() completion.on_accept_suggestion() end, { desc = 'Supermaven: suggestie accepteren' })
vim.keymap.set('i', '<C-j>', function() completion.on_accept_suggestion_word() end, { desc = 'Supermaven: één woord accepteren' })
vim.keymap.set('i', '<C-]>', function() completion.on_dispose_inlay() end, { desc = 'Supermaven: suggestie wegklikken' })

-- :SupermavenInfo -- wel bruikbare status. De agent bewaart zijn account-state in
-- ~/.supermaven/config.json; een api_key die met "free-" begint betekent Free Tier.
vim.api.nvim_create_user_command('SupermavenInfo', function()
  local lines = { 'agent draait: ' .. (require('supermaven-nvim.api').is_running() and 'ja' or 'nee') }

  local path = vim.fs.joinpath(vim.uv.os_homedir(), '.supermaven', 'config.json')
  local ok, cfg = pcall(function() return vim.json.decode(table.concat(vim.fn.readfile(path), '\n')) end)

  if not ok or type(cfg) ~= 'table' then
    table.insert(lines, 'account: niet ingelogd (draai :SupermavenUseFree)')
  else
    local key = cfg.api_key or ''
    table.insert(lines, 'account: ' .. (key:match '^free%-' and 'Free Tier' or key ~= '' and 'Pro' or 'onbekend'))
  end

  table.insert(lines, 'log: ' .. tostring(require('supermaven-nvim.logger'):get_log_path()))
  vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO, { title = 'Supermaven' })
end, { desc = 'Supermaven: status en account' })
