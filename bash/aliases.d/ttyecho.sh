# only echo when stdout is a terminal
ttyecho() { [[ -t 1 ]] && echo "$@"; }
