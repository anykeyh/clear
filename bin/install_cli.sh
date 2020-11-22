#!/bin/sh

CRYSTAL_BIN=$(which crystal)
CURR_PWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SRC_DIR=CURR_PWD/../src

compile() {
  mkdir -t /tmp/.drop-cli
  $CRYSTAL_BIN build --release SRC_DIR/clear/cli.cr -o /tmp/.drop-cli/drop-cli
}

clean() {
  test -d /tmp/.drop-cli && rm -r /tmp/.drop-cli
}