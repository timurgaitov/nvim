#!/bin/bash
set -e

brew install neovim tree-sitter-cli ripgrep gopls pyrefly
go install github.com/go-delve/delve/cmd/dlv@latest
python3 -m venv ~/.local/share/debugpy
~/.local/share/debugpy/bin/pip install debugpy
