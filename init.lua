-- Global Key Mappings
vim.keymap.set("n", "<Space>", "<Nop>", { silent = true, remap = false })
vim.g.mapleader = " "
vim.opt.number = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true
vim.opt.showmatch = true

-- Bootstrap lazy.nvim + Plugins
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

local plugins = {
  "nvim-lua/plenary.nvim",
  {"williamboman/mason.nvim", build = ":MasonUpdate"},
  "williamboman/mason-lspconfig.nvim",
  "neovim/nvim-lspconfig",
  "jose-elias-alvarez/null-ls.nvim",
  {"jay-babu/mason-null-ls.nvim", event = {"BufReadPre", "BufNewFile"}},
  {"ms-jpq/coq_nvim", branch = "coq", build = ":COQdeps", commit = "84ec5fa"},
  {"ms-jpq/coq.artifacts", branch = "artifacts"},
  {"ms-jpq/coq.thirdparty", branch = "3p"},
  {"nvim-treesitter/nvim-treesitter", build = ":TSUpdate"},
  "rebelot/kanagawa.nvim",
}
require("lazy").setup(plugins)

vim.cmd("colorscheme kanagawa")

-- Configure LSP + Linters + Formatters
vim.g.coq_settings = { auto_start = true }
local coq = require("coq")

local server_maps = function(opts)
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts) -- goto def
  vim.keymap.set("n", "K", vim.lsp.buf.hover, opts) -- see docs
  vim.keymap.set("n", "<leader>fo", function() -- format
    vim.lsp.buf.format({ async = true })
  end, opts)
  vim.keymap.set("v", "<leader>fo", function() -- format
    vim.lsp.buf.format({ async = true })
    vim.print("DOING FORMAT IN VISUAL MODE")
  end, opts)
end

local handlers = {
   -- The first entry (without a key) will be the default handler
   -- and will be called for each installed server that doesn't have
   -- a dedicated handler.
   function (server_name) -- default handler (optional)
       local lspserver = require("lspconfig")[server_name]
       lspserver.setup(coq.lsp_ensure_capabilities({
         on_attach = function(_, buffer)
           server_maps({buffer = buffer})
         end,
       }))
   end,
   -- Next, you can provide targeted overrides for specific servers.
   -- ["rust_analyzer"] = function ()
   --    require("rust-tools").setup {}
   -- end,
   ["lua_ls"] = function ()
     require("lspconfig")["lua_ls"].setup {
       settings = {
         Lua = {
           diagnostics = {
             globals = { "vim" }
           }
         }
       }
     }
   end,
}

vim.cmd("COQnow --shut-up")

require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = {
    -- Python
    pyright = {},
    pyink = {},
    ruff = {},
    ruff_lsp = {},
    
    -- Lua
    stylua = {},
    lua_ls = {}
  },
  handlers = handlers})
require("mason-null-ls").setup({
  automatic_installation = false,
  automatic_setup = true,
  handlers = {}
})
require("null-ls").setup()

