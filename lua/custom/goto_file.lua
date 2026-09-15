-- Slimme "ga naar definitie of bestand".
--
-- gd probeert eerst een LSP-definitie. Levert dat niets op (of is er geen LSP), dan valt
-- hij terug op het bestand onder de cursor, inclusief `@/...` alias-resolutie en het
-- raden van extensies. Zo werkt dezelfde toets op een component-naam en op een importpad.
--
-- Bestandsnaam is goto_file.lua, niet goto.lua: `goto` is een LuaJIT-keyword.

local M = {}

local EXTS = { '.ts', '.tsx', '.js', '.jsx', '.mjs', '.cjs', '.json', '.css', '.scss', '.mdx' }
local INDEX = { '/index.ts', '/index.tsx', '/index.js', '/index.jsx' }
local ROOT_MARKERS = { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' }

local alias_cache = {}

function M.root(bufnr) return vim.fs.root(bufnr or 0, ROOT_MARKERS) or assert(vim.uv.cwd()) end

-- Leest compilerOptions.paths uit de dichtstbijzijnde tsconfig/jsconfig.
-- Zonder baseUrl (moduleResolution "bundler") zijn targets relatief aan de map van de tsconfig.
local function aliases_for(root)
  if alias_cache[root] then return alias_cache[root] end

  local map = { ['@/'] = { 'src/' } }

  for _, name in ipairs { 'tsconfig.json', 'jsconfig.json' } do
    local file = vim.fs.joinpath(root, name)
    if vim.uv.fs_stat(file) then
      local text = table.concat(vim.fn.readfile(file), '\n')
      text = text:gsub('^%s*//[^\n]*', ''):gsub('\n%s*//[^\n]*', '') -- grove JSONC-strip
      local ok, json = pcall(vim.json.decode, text)
      local paths = ok and type(json) == 'table' and vim.tbl_get(json, 'compilerOptions', 'paths')
      if type(paths) == 'table' and next(paths) then
        map = {}
        for pat, targets in pairs(paths) do
          local list = {}
          for _, t in ipairs(targets) do
            table.insert(list, (t:gsub('%*$', ''):gsub('^%./', '')))
          end
          map[(pat:gsub('%*$', ''))] = list
        end
      end
      break
    end
  end

  alias_cache[root] = map
  return map
end

local function first_file(base)
  local tries = { base }
  for _, ext in ipairs(EXTS) do
    table.insert(tries, base .. ext)
  end
  for _, idx in ipairs(INDEX) do
    table.insert(tries, base .. idx)
  end
  for _, path in ipairs(tries) do
    local stat = vim.uv.fs_stat(path)
    if stat and stat.type == 'file' then return path end
  end
end

--- Zet een import-specifier om naar een absoluut pad, of nil.
function M.resolve(spec, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if type(spec) ~= 'string' or spec == '' then return nil end

  spec = spec:gsub('%?.*$', ''):gsub('#.*$', '')

  if spec:sub(1, 1) == '~' then return first_file(vim.fn.expand(spec)) end
  if spec:sub(1, 1) == '/' then return first_file(spec) end
  if spec:sub(1, 1) == '.' then
    local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
    return first_file(vim.fs.normalize(vim.fs.joinpath(dir, spec)))
  end

  local root = M.root(bufnr)
  for prefix, targets in pairs(aliases_for(root)) do
    if #prefix > 0 and spec:sub(1, #prefix) == prefix then
      local rest = spec:sub(#prefix + 1)
      for _, target in ipairs(targets) do
        local hit = first_file(vim.fs.joinpath(root, target .. rest))
        if hit then return hit end
      end
    end
  end

  -- Laatste redmiddel. Leest package.json exports/main niet; LSP dekt bare imports al.
  return first_file(vim.fs.joinpath(root, 'node_modules', spec))
end

--- De string onder de cursor: eerst treesitter, dan een quoted-region scan, dan <cfile>.
function M.spec_under_cursor()
  local ok, node = pcall(vim.treesitter.get_node)
  if ok and node then
    local t = node:type()
    if t == 'string_fragment' or t == 'string_content' then return vim.treesitter.get_node_text(node, 0) end
    if t == 'string' or t == 'template_string' then return (vim.treesitter.get_node_text(node, 0):gsub('^["\'`]', ''):gsub('["\'`]$', '')) end
  end

  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local init = 1
  while true do
    local s, e, text = line:find('["\'`]([^"\'`]*)["\'`]', init)
    if not s then break end
    if col >= s and col <= e then return text end
    init = e + 1
  end

  return vim.fn.expand '<cfile>'
end

--- Go-to-file met alias- en extensie-resolutie.
function M.goto_file()
  local spec = M.spec_under_cursor()
  local path = M.resolve(spec)
  if path then
    vim.cmd "normal! m'"
    vim.cmd.edit(vim.fn.fnameescape(path))
    return true
  end
  vim.notify(('gd: geen definitie of bestand voor %q'):format(spec or ''), vim.log.levels.WARN)
  return false
end

--- Hook voor 'includeexpr', zodat de kale gf dezelfde resolutie krijgt.
function M.includeexpr(fname) return M.resolve(fname) or fname end

--- Slimme gd: LSP-definitie, met automatische fallback naar go-to-file.
---
--- Let op: vim.lsp.buf.definition{on_list=...} kan hier niet gebruikt worden. get_locations()
--- in de runtime doet `notify("No locations found"); return` vóór de on_list-tak, dus je
--- kunt "geen resultaat" niet detecteren. Vandaar buf_request_all — die roept zijn handler
--- op zijn beurt niet aan als geen client de method ondersteunt, dus dat checken we vooraf.
function M.definition()
  local bufnr = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  local method = vim.lsp.protocol.Methods.textDocument_definition

  if #vim.lsp.get_clients { bufnr = bufnr, method = method } == 0 then return M.goto_file() end

  local from = vim.fn.getpos '.'
  from[1] = bufnr
  local tagname = vim.fn.expand '<cword>'

  vim.lsp.buf_request_all(bufnr, method, function(client) return vim.lsp.util.make_position_params(win, client.offset_encoding) end, function(results)
    local items = {}
    for client_id, res in pairs(results) do
      local client = vim.lsp.get_client_by_id(client_id)
      if client and not res.err and res.result then
        local locations = vim.islist(res.result) and res.result or { res.result }
        vim.list_extend(items, vim.lsp.util.locations_to_items(locations, client.offset_encoding))
      end
    end

    if #items == 0 then return M.goto_file() end

    if #items == 1 then
      local item = items[1]
      vim.cmd "normal! m'"
      vim.fn.settagstack(vim.fn.win_getid(win), { items = { { tagname = tagname, from = from } } }, 't')
      local target = item.bufnr or vim.fn.bufadd(item.filename)
      vim.bo[target].buflisted = true
      vim.api.nvim_win_set_buf(win, target)
      vim.api.nvim_win_set_cursor(win, { item.lnum, item.col - 1 })
      vim.cmd 'normal! zv'
      return
    end

    vim.fn.setqflist({}, ' ', { title = 'LSP definitions', items = items })
    local ok, telescope = pcall(require, 'telescope.builtin')
    if ok then
      telescope.quickfix()
    else
      vim.cmd 'botright copen'
    end
  end)
end

return M
