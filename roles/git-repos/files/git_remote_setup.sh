#!/usr/bin/env bash
set -e
old_remotes="$(git remote -v)"

if "$GITHUB_ACCESS"; then
  origin="$GITHUB_URL"
  backup="$SERVER_URL"
else
  origin="$SERVER_URL"
  backup=""
fi

current_origin="$(git remote get-url origin || true)"
if [ "$current_origin" != "$origin" ]; then
  [ -z "$current_origin" ] || git remote remove origin
  git remote add origin "$origin"
  git fetch origin
  git branch --set-upstream-to "origin/$(git branch --show-current)" "$(git branch --show-current)"
fi

current_backup="$(git remote get-url backup || true)"
if [ "current_backup" != "$backup" ]; then
  [ -z "$current_backup" ] || git remote remove backup
  [ -n "$backup" ] && git remote add backup "$backup"
fi

if [ "$old_remotes" = "$(git remote -v)" ]; then
  echo "remotes unchanged"
fi
