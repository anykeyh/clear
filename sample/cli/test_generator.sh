#!/bin/sh

CMD="crystal sample/cli/cli.cr --"

rm -r "./generated"
$CMD generate model -d "./generated" test