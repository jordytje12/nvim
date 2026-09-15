-- C/C++ debugging via codelldb.
--
-- Dit vervangt kickstart.plugins.debug (die is op Go gericht en trekt delve en
-- nvim-dap-go binnen). Zelfde plugins, andere adapter.

vim.pack.add {
  'https://github.com/mfussenegger/nvim-dap',
  'https://github.com/rcarriga/nvim-dap-ui',
  'https://github.com/nvim-neotest/nvim-nio', -- vereist door dap-ui
  'https://github.com/theHamsta/nvim-dap-virtual-text',
}

local dap = require 'dap'
local dapui = require 'dapui'

---@diagnostic disable-next-line: missing-fields
dapui.setup {
  icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
}
require('nvim-dap-virtual-text').setup {}

-- dap-ui automatisch openen/sluiten rond een sessie
dap.listeners.before.attach.dapui_config = function() dapui.open() end
dap.listeners.before.launch.dapui_config = function() dapui.open() end
dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

-- codelldb draait als server op een vrije poort; mason.nvim zet zijn bin-dir op PATH
dap.adapters.codelldb = {
  type = 'server',
  port = '${port}',
  executable = {
    command = 'codelldb',
    args = { '--port', '${port}' },
  },
}

dap.configurations.cpp = {
  {
    name = 'Launch',
    type = 'codelldb',
    request = 'launch',
    program = function() return vim.fn.input('Pad naar executable: ', vim.fn.getcwd() .. '/build/', 'file') end,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
  },
}

dap.configurations.c = dap.configurations.cpp

-- <leader>ds is niet gebruikt: die is al van kickstart (diagnostic loclist).
local map = function(lhs, rhs, desc) vim.keymap.set('n', lhs, rhs, { desc = desc }) end

map('<leader>db', function() dap.toggle_breakpoint() end, 'DAP breakpoint')
map('<leader>dB', function() dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ') end, 'DAP conditional breakpoint')
map('<leader>dc', function() dap.continue() end, 'DAP continue / start')
map('<leader>di', function() dap.step_into() end, 'DAP step into')
map('<leader>do', function() dap.step_over() end, 'DAP step over')
map('<leader>dO', function() dap.step_out() end, 'DAP step out')
map('<leader>dt', function() dap.terminate() end, 'DAP terminate')
map('<leader>du', function() dapui.toggle() end, 'DAP UI toggle')
