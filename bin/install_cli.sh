#!/bin/sh

$USER_BIN_PATH=$(echo ~/bin)

echo "Building clear-cli binaries..."
crystal --release src/clear-cli.cr -o $USER_BIN_PATH/clear-cli
