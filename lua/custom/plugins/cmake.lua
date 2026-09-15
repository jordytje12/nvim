-- CMake: configureren, bouwen, draaien en debuggen zonder Neovim te verlaten.
--
-- Haakt in op de nvim-dap + codelldb uit cpp.lua, dus <leader>cd debugt met dezelfde
-- adapter als <leader>dc.

-- nvim-dap staat hier bewust ook in, ook al zet cpp.lua hem al neer. cmake-tools doet bij
-- setup een `pcall(require, "dap")` en registreert :CMakeDebug alleen als dat lukt. De
-- laadvolgorde van lua/custom/plugins/* ligt niet vast, dus zonder deze regel verdwijnt
-- :CMakeDebug zodra cmake.lua toevallig vóór cpp.lua draait. vim.pack dedupliceert op URL.
vim.pack.add {
  'https://github.com/mfussenegger/nvim-dap',
  'https://github.com/Civitasv/cmake-tools.nvim',
}

require('cmake-tools').setup {
  -- Ninja zoals je gewend bent, en de compile-database die clangd nodig heeft.
  cmake_generate_options = { '-GNinja', '-DCMAKE_EXPORT_COMPILE_COMMANDS=1' },

  -- Default is out/${variant:buildType}. Wij houden `build`, want daar wijst je .clangd
  -- naar (CompilationDatabase: build) en daar staat je bestaande compile_commands.json.
  cmake_build_directory = 'build',

  cmake_soft_link_compile_commands = true,

  -- focus/start_insert blijven hier bewust UIT, ondanks dat je ze zou willen.
  --
  -- cmake-tools heeft een bug in terminal.lua: bestaat het runner-venster nog niet, dan
  -- maakt hij een nieuwe split maar werkt `win_id` niet bij (die blijft -1). Meteen daarna
  -- doet de focus-tak `nvim_set_current_win(-1)` -> "Invalid window id: -1". Daarom zag je
  -- dat alleen sóms: met een al geopend runner-venster gaat het wel goed.
  --
  -- De autocmd onderaan dit bestand doet de focus zelf, en controleert het venster wel.
  cmake_runner = {
    name = 'terminal',
    opts = {
      focus = false,
      start_insert = false,
    },
  },

  cmake_dap_configuration = {
    name = 'cpp',
    type = 'codelldb',
    request = 'launch',
    stopOnEntry = false,
    runInTerminal = true,
    console = 'integratedTerminal',
  },
}

local map = function(lhs, rhs, desc) vim.keymap.set('n', lhs, rhs, { desc = desc }) end

map('<leader>cg', '<cmd>CMakeGenerate<cr>', '[C]Make [g]enereren')
map('<leader>cb', '<cmd>CMakeBuild<cr>', '[C]Make [b]ouwen')
map('<leader>cr', '<cmd>CMakeRun<cr>', '[C]Make [r]unnen')
map('<leader>cd', '<cmd>CMakeDebug<cr>', '[C]Make [d]ebuggen')
-- cmake-tools kent twee losse keuzes, en dat is een makkelijke valkuil:
--   build target  = wat :CMakeBuild compileert
--   launch target = wat :CMakeRun en :CMakeDebug uitvoeren
-- Wil je een ander programma draaien, dan moet je de launch target hebben (<leader>cl).
map('<leader>ct', '<cmd>CMakeSelectBuildTarget<cr>', '[C]Make build-[t]arget kiezen')
map('<leader>cl', '<cmd>CMakeSelectLaunchTarget<cr>', '[C]Make [l]aunch-target kiezen (wat <leader>cr draait)')
map('<leader>cv', '<cmd>CMakeSelectBuildType<cr>', '[C]Make build-type (Debug/Release)')
map('<leader>cc', '<cmd>CMakeClean<cr>', '[C]Make [c]lean')

-- cmake-tools heeft twee aparte terminals: de "executor" (build-uitvoer) en de "runner"
-- (waar jouw programma draait). <leader>cr opent die tweede. Close verbergt het venster,
-- Stop kapt een nog lopend proces af.
map('<leader>cq', function()
  vim.cmd 'CMakeCloseRunner'
  vim.cmd 'CMakeCloseExecutor'
end, '[C]Make: terminal sluiten ([q]uit)')

map('<leader>cs', function()
  vim.cmd 'CMakeStopRunner'
  vim.cmd 'CMakeStopExecutor'
end, '[C]Make: lopend proces [s]toppen')

-- Focus op de runner-terminal, maar dan zonder de upstream-bug hierboven.
--
-- vim.schedule is nodig omdat cmake-tools na TermOpen nog `wincmd p` kan doen; wij willen
-- het laatste woord. Alles is defensief: bestaat het venster niet meer, dan gebeurt er niets
-- in plaats van een foutmelding midden in je scherm.
vim.api.nvim_create_autocmd('TermOpen', {
  group = vim.api.nvim_create_augroup('UserCMakeRunnerFocus', { clear = true }),
  callback = function(args)
    -- De naamcheck moet BINNEN de schedule: op het moment van TermOpen heet de buffer nog
    -- "term://...:/bin/zsh". Pas daarna hernoemt cmake-tools hem naar "[CMakeTools]: ...".
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(args.buf) then return end
      if not vim.api.nvim_buf_get_name(args.buf):find('Runner Terminal', 1, true) then return end

      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == args.buf then
          vim.api.nvim_set_current_win(win)
          vim.cmd 'startinsert'
          return
        end
      end
    end)
  end,
})
