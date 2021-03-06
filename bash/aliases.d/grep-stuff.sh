#!/usr/bin/env bash
# various grep shorthands
alias igrep='egrep -i'
alias hh='history | igrep '
alias ff='find . | igrep '
alias lgrep='l | igrep '
alias dpkgrep='dpkg --list | igrep '

# grep for processes
# shellcheck disable=2009
psgrep() { q="$1"; ps aux | grep -Ei "${q:0:1}.{0}${q:1}"; }
