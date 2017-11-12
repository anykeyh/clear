#!/bin/sh

for f in $(find ./spec -name "*_spec.cr")
do
  crystal spec $f
done