-- Options
vim.opt.relativenumber = true
vim.opt.langmap = "ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯ;ABCDEFGHIJKLMNOPQRSTUVWXYZ,фисвуапршолдьтщзйкыегмцчня;abcdefghijklmnopqrstuvwxyz"

vim.keymap.set("n", "<Esc><Esc>", "<cmd>nohlsearch<CR>", { silent = true })

-- Leader key (must be set before lazy)
vim.g.mapleader = " "
vim.cmd.colorscheme("default")

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Plugins
require("lazy").setup({
  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    main = "nvim-treesitter",
    opts = {
      ensure_installed = { "go", "python" },
      highlight = { enable = true },
    },
  },

  -- Completion
  {
    "saghen/blink.cmp",
    version = "*",
    opts = {
      keymap = {
        preset = "default",
        ["<CR>"] = { "accept", "fallback" },
      },
      sources = {
        default = { "lsp", "path" },
      },
    },
  },

  -- Debugger
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "leoluz/nvim-dap-go",
      "mfussenegger/nvim-dap-python",
    },
    config = function()
      require("dap-go").setup()
      require("dap-python").setup("~/.local/pipx/venvs/debugpy/bin/python")

      local map = function(key, fn) vim.keymap.set("n", key, fn) end
      map("<leader>db", require("dap").toggle_breakpoint)
      map("<leader>dc", require("dap").continue)
      map("<leader>do", require("dap").step_over)
      map("<leader>di", require("dap").step_into)
      map("<leader>dq", require("dap").terminate)
      map("<leader>dr", require("dap").repl.open)
    end,
  },

  -- Database
  { "tpope/vim-dadbod" },
  { "kristijanhusak/vim-dadbod-ui", dependencies = { "tpope/vim-dadbod" } },
  { "kristijanhusak/vim-dadbod-completion", dependencies = { "tpope/vim-dadbod" } },

  -- Diff viewer
  {
    "sindrets/diffview.nvim",
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<CR>" },
      { "<leader>gh", "<cmd>DiffviewFileHistory<CR>" },
      { "<leader>gq", "<cmd>DiffviewClose<CR>" },
    },
  },

  -- Telescope (fuzzy finder)
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader><leader>", builtin.find_files)
      vim.keymap.set("n", "<leader>/", builtin.live_grep)
      vim.keymap.set("n", "<leader>b", builtin.buffers)
    end,
  },
})

-- LSP
vim.lsp.config("gopls", {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork" },
  root_markers = { "go.work", "go.mod", ".git" },
  capabilities = require("blink.cmp").get_lsp_capabilities(),
})

vim.lsp.config("pyright", {
  cmd = { "pyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "setup.py", ".git" },
  capabilities = require("blink.cmp").get_lsp_capabilities(),
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = "workspace",
      },
    },
  },
})

vim.lsp.enable({ "gopls", "pyright" })

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function()
    local clients = vim.lsp.get_clients({ bufnr = 0, name = "gopls" })
    if #clients == 0 then return end
    vim.lsp.buf.code_action({
      context = { only = { "source.organizeImports" } },
      apply = true,
      async = false,
    })
    vim.lsp.buf.format({ async = false })
  end,
})

-- LSP keymaps
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local map = function(key, fn) vim.keymap.set("n", key, fn, { buffer = args.buf }) end
    map("gd", vim.lsp.buf.definition)
    map("gi", vim.lsp.buf.implementation)
    map("gr", vim.lsp.buf.references)
    map("K",  vim.lsp.buf.hover)
    map("<leader>de", vim.diagnostic.open_float)
    map("[d", vim.diagnostic.goto_prev)
    map("]d", vim.diagnostic.goto_next)
  end,
})

vim.diagnostic.config({
  virtual_text = true,         -- Show errors inline
  signs = true,                -- Show signs in gutter
  underline = true,            -- Underline error text
  update_in_insert = false,    -- Don't spam while typing
  severity_sort = true,        -- Sort by severity
  float = {
    border = 'rounded',
    source = 'always',
  },
})

