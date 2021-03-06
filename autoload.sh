#!/bin/bash

# First, automatically discover and load exports and functions for core utilities.
for script in $(find $(dirname ${BASH_SOURCE[0]})/core -type f -perm -u+r 2>/dev/null | xargs); do
  source $script; 
done

# Next, automatically discover and load user-created exports and functions.
for script in $(find $(dirname ${BASH_SOURCE[0]})/autoload -type f -perm -u+r 2>/dev/null | xargs); do
  source $script; 
done