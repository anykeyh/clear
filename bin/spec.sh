#!/bin/sh

for f in $(find ./spec -name "*.cr")
do
  crystal spec $f
done