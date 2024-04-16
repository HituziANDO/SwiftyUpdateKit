#!/bin/sh

if [ -d .husky ]; then
  rm -rf .husky
fi

npx husky install && npx husky add .husky/pre-commit "npx --no-install lint-staged"
