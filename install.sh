#!/bin/bash
set -e

brew install neovim tree-sitter-cli ripgrep gopls pyrefly
go install github.com/go-delve/delve/cmd/dlv@latest
