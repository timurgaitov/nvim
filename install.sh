#!/bin/bash
set -e

brew install neovim tree-sitter-cli ripgrep gopls pyright pipx
go install github.com/go-delve/delve/cmd/dlv@latest
pipx install debugpy
