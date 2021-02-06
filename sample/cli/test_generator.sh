#!/bin/sh

CMD="crystal run sample/cli/cli.cr -- clear"

rm -r "./generated"
$CMD generate model -d "./generated" test