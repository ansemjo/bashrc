#!/usr/bin/env bash
# always alias vim when it exists
if [[ -x /usr/bin/vim ]]; then
  alias vi=vim
  export EDITOR=vim
fi
