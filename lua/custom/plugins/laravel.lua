-- Laravel: artisan/routes/tinker pickers, Laravel-aware gf en completion.
--
-- nui.nvim en plenary.nvim komen ook via kickstart.plugins.neo-tree binnen; vim.pack
-- dedupliceert op URL, dus ze hier ook noemen is veilig en houdt de module op zichzelf staand.
--
-- Let op: deze plugin heeft geen :Laravel ex-command. Alles loopt via de globale
-- `Laravel`-tabel die setup() aanmaakt (Laravel.pickers.*, Laravel.commands.run(...)).

vim.pack.add {
  'https://github.com/MunifTanjim/nui.nvim',
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/nvim-neotest/nvim-nio',
  'https://github.com/adalessa/laravel.nvim',
}

require('laravel').setup {
  features = {
    pickers = { provider = 'telescope' },
  },
}

local map = function(lhs, rhs, desc) vim.keymap.set('n', lhs, rhs, { desc = desc }) end

map('<leader>ll', function() Laravel.pickers.laravel() end, 'Laravel: picker')
map('<leader>la', function() Laravel.pickers.artisan() end, 'Laravel: [a]rtisan')
map('<leader>lr', function() Laravel.pickers.routes() end, 'Laravel: [r]outes')
map('<leader>lm', function() Laravel.pickers.make() end, 'Laravel: [m]ake')
map('<leader>lc', function() Laravel.pickers.commands() end, 'Laravel: custom [c]ommands')
map('<leader>lo', function() Laravel.pickers.resources() end, 'Laravel: res[o]urces')
map('<leader>lh', function() Laravel.run 'artisan docs' end, 'Laravel: docs')
map('<leader>lt', function() Laravel.commands.run 'actions' end, 'Laravel: code ac[t]ions')
map('<leader>lu', function() Laravel.commands.run 'hub' end, 'Laravel: artisan h[u]b')
map('<leader>lp', function() Laravel.commands.run 'command_center' end, 'Laravel: command center')
map('<C-g>', function() Laravel.commands.run 'view:finder' end, 'Laravel: view finder')

-- Laravel-aware gf voor route()/view()/config()/env()/Inertia::render(), met de gewone
-- gf als die niet van toepassing is.
--
-- Buffer-lokaal en alleen in php/blade: globaal zou dit ook de gf in .tsx en .py
-- afvangen, en daar doet editor.lua juist zijn eigen alias-resolutie via 'includeexpr'.
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('UserLaravelGf', { clear = true }),
  pattern = { 'php', 'blade' },
  callback = function(args)
    vim.keymap.set('n', 'gf', function()
      local ok, on_resource = pcall(function() return Laravel.app('gf').cursorOnResource() end)
      if ok and on_resource then return "<cmd>lua Laravel.commands.run('gf')<cr>" end
      return 'gf'
    end, { buffer = args.buf, expr = true, noremap = true, desc = 'Laravel: go to resource' })
  end,
})
