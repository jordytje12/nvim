-- Neo-tree smaller maken dan de standaard 40 kolommen.
--
-- Dit roept setup() een tweede keer aan, ná kickstart.plugins.neo-tree (SECTION 10 laadt
-- `custom.plugins` daarna). Zo hoeft lua/kickstart/plugins/neo-tree.lua niet aangepast te
-- worden en blijft een `git pull` van upstream conflictvrij.
--
-- Let op: neo-tree's setup() vervangt de vorige config in plaats van erop te stapelen,
-- dus de `\`-mapping uit kickstart staat hieronder opnieuw. Verandert die daar ooit,
-- dan moet dit mee.

local BREEDTE = 30

require('neo-tree').setup {
  window = {
    width = BREEDTE,
    mappings = {
      -- Zelfde als kickstart: `\` sluit de tree weer.
      ['\\'] = 'close_window',
    },
  },
  filesystem = {
    window = {
      width = BREEDTE,
      mappings = {
        ['\\'] = 'close_window',
      },
    },
  },
}

-- Breedte live bijstellen zonder de config aan te raken. Handig om je eigen voorkeur
-- te vinden; zet die daarna in BREEDTE hierboven.
vim.api.nvim_create_user_command('NeotreeWidth', function(opts)
  local n = tonumber(opts.args)
  if not n then
    vim.notify('Gebruik: :NeotreeWidth 30', vim.log.levels.WARN)
    return
  end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == 'neo-tree' then vim.api.nvim_win_set_width(win, n) end
  end
end, { nargs = 1, desc = 'Neo-tree breedte tijdelijk aanpassen' })
