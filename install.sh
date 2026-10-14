#!/bin/bash
set -e

brew install neovim tree-sitter-cli ripgrep gopls pyrefly uv
go install github.com/go-delve/delve/cmd/dlv@latest
uv tool install debugpy
