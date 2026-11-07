-- Options
vim.opt.number = true
vim.opt.clipboard = "unnamedplus"
vim.opt.diffopt:append("iwhite")
vim.opt.langmap = "ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯ;ABCDEFGHIJKLMNOPQRSTUVWXYZ,фисвуапршолдьтщзйкыегмцчня;abcdefghijklmnopqrstuvwxyz"
  .. [[,жЖэЭхХъЪбБюЮёЁ.\,;\;:'"[{]}\,<.>`~/?]]

-- Indentation: 4 columns wide, for both tabs and spaces
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4

-- Leader key (must be set before lazy)
vim.g.mapleader = " "

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { silent = true })
vim.keymap.set("n", "<leader>e", "<cmd>Ex<CR>")

-- Toggle tabs/spaces for the current buffer (no conversion of existing text)
vim.keymap.set("n", "<leader>i", function()
  vim.bo.expandtab = not vim.bo.expandtab
  print(vim.bo.expandtab and "spaces" or "tabs")
end)

-- Open file in the macOS default app (e.g. images in Preview).
-- In netrw, opens the file under the cursor without loading a buffer.
vim.keymap.set("n", "<leader>o", function()
  local path
  if vim.bo.filetype == "netrw" then
    local dir = vim.b.netrw_curdir or vim.fn.getcwd()
    path = dir .. "/" .. vim.fn.expand("<cfile>")
  else
    path = vim.fn.expand("%:p")
  end
  vim.fn.jobstart({ "open", path })
end)

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
    config = function()
      -- Installs in the background; no-op once parsers are present
      require("nvim-treesitter").install({ "go", "python" })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "go", "python" },
        -- pcall: the parser may still be installing on first run
        callback = function() pcall(vim.treesitter.start) end,
      })
    end,
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

  -- Git change signs (gutter)
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local map = function(key, fn) vim.keymap.set("n", key, fn, { buffer = bufnr }) end
        map("]c", function() gs.nav_hunk("next") end)
        map("[c", function() gs.nav_hunk("prev") end)
        map("<leader>gp", gs.preview_hunk)
        map("<leader>gb", gs.blame_line)
      end,
    },
  },

  -- Diff viewer
  {
    "sindrets/diffview.nvim",
    opts = { use_icons = false },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen -w<CR>" },
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

vim.lsp.config("pyrefly", {
  cmd = { "pyrefly", "lsp" },
  filetypes = { "python" },
  root_markers = { "pyrefly.toml", "pyproject.toml", "setup.py", ".git" },
  capabilities = require("blink.cmp").get_lsp_capabilities(),
})

vim.lsp.config("clangd", {
  cmd = { "clangd", "--background-index", "--clang-tidy" },
  filetypes = { "c", "cpp", "objc", "objcpp" },
  root_markers = { "compile_commands.json", "compile_flags.txt", ".clangd", ".git" },
  capabilities = require("blink.cmp").get_lsp_capabilities(),
})

vim.lsp.enable({ "gopls", "pyrefly", "clangd" })

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
    map("<leader>rn", vim.lsp.buf.rename)
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

