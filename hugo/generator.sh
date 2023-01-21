#!/usr/bin/env bash

# Generate static website
hugo -t hugo-theme-shell

# Copy to root dir
cp -r public/* ../

