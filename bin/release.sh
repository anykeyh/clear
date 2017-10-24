#!/bin/sh

crystal spec && crystal doc && git add ./doc && git commit -a