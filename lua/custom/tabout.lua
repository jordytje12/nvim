-- "Tab eruit springen": staat de cursor vlak voor een sluitteken, dan springt <Tab>
-- daaroverheen in plaats van een tab in te voegen.
--
-- Zo kun je `foo("bar|")` met tweemaal Tab verlaten zonder naar de pijltjes te grijpen.
-- Wordt aangeroepen vanuit blink.cmp's <Tab>-keten in init.lua, na 'snippet_forward',
-- zodat springen binnen een snippet voorrang houdt.

local M = {}

-- Alleen sluittekens. Openingstekens overslaan zou je juist uit je code weg laten springen.
local CLOSERS = {
  [')'] = true,
  [']'] = true,
  ['}'] = true,
  ['"'] = true,
  ["'"] = true,
  ['`'] = true,
  ['>'] = true,
}

--- Springt één sluitteken naar rechts. Geeft true terug als er gesprongen is, zodat
--- blink weet dat de toets afgehandeld is en niet alsnog een tab invoegt.
---
--- De sprong gaat bewust via feedkeys en niet via nvim_win_set_cursor: blink registreert
--- zijn keymaps als expressie-mapping, en daarin is het verplaatsen van de cursor verboden
--- (`:help :map-expr`) -- Neovim zet de cursor daarna gewoon terug. feedkeys zet <Right>
--- in de wachtrij, die pas verwerkt wordt als de mapping klaar is, en dat mag wel.
---@return boolean
function M.jump()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]

  -- In insert mode is `col` het aantal bytes vóór de cursor, dus het teken er direct
  -- achter is byte col+1 (Lua-strings zijn 1-geïndexeerd).
  if not CLOSERS[line:sub(col + 1, col + 1)] then return false end

  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Right>', true, false, true), 'n', false)
  return true
end

return M
