#!/usr/bin/env bash

# Set some defaults for the prompt line; defaults to false if unset

# use color?
PS1_COLORFUL=true
# show exit status of last command?
PS1_STATUS=true
# show number of background jobs?
PS1_JOBS=true
# display username?
PS1_USERNAME=false
# display hostname?
PS1_HOSTNAME=true
# display working directory? [true|full|relative]
PS1_DIRECTORY=relative
# display nothing but the prompt symbol?
PS1_ONLYPROMPT=false
# display git prompt? (yes/no)
# (requires /usr/share/git/completion/git-prompt.sh)
PS1_GIT=true
# display kubernetes context and namespace
PS1_KUBERNETES=false
# use linewrap indicator trick
PS1_LINEWRAP=true

# defaults for __git_ps1
GIT_PS1_SHOWDIRTYSTATE=true
GIT_PS1_SHOWSTASHSTATE=true
GIT_PS1_SHOWUNTRACKEDFILES=true
GIT_PS1_SHOWUPSTREAM=auto

# prompt_builder; is called after every command to refresh prompt
function prompt_builder {

  # get exit status of previously run command
  local exitstatus=$?

  # save settings; set case-insensitivity for truthy/falsy
  settings=$(shopt -p)
  shopt -s nocasematch

  # check if a variable has truthy value
  truthy() { [[ $1 =~ true|y(es)|on ]]; }
  falsy() { truthy "$1" && return 1 || return 0; }

  # count background jobs
  _jobscounter() {
    local j=($(jobs -p))
    [[ ${#j[@]} -gt 0 ]] && printf '%d ' "${#j[@]}";
  }

  # empty PS1 to be built
  PS1=""

  # use color at all?
  if truthy "$PS1_COLORFUL"; then

    # color escape sequences
    local   reset='\[\e[00m\]'
    local    bold='\[\e[01m\]'

    local     red='\[\e[31m\]'
    local   green='\[\e[32m\]'
    local  yellow='\[\e[33m\]'
    local    blue='\[\e[34m\]'
    local magenta='\[\e[35m\]'
    local    cyan='\[\e[36m\]'

    if [[ -n $PS1_COLOR ]]; then
      # match user-defined color
      case "$PS1_COLOR" in
        red)      local color="$bold$red"     ;;
        green)    local color="$bold$green"   ;;
        yellow)   local color="$bold$yellow"  ;;
        blue)     local color="$bold$blue"    ;;
        magenta)  local color="$bold$magenta" ;;
        cyan)     local color="$bold$cyan"    ;;
        bold)     local color="$bold"         ;;
        *)        local color=""              ;;
      esac
    else
      # otherwise root = red and others = green
      if [[ $EUID = 0 ]]; then
        local color="$bold$red"
      else
        local color="$bold$green"
      fi
    fi

  fi

  # print linewrap indicator and position cursor at the beginning
  # ref: https://www.vidarholen.net/contents/blog/?p=878
  local linewrap='¶'
  if truthy "$PS1_LINEWRAP"; then
    printf "\033[33m%s\033[0m%$((COLUMNS-1))s\\r" "$linewrap"
  fi

  # <username>
  falsy "$PS1_ONLYPROMPT" && truthy "$PS1_USERNAME" && \
    PS1+="$color\u$reset ";

  # @<hostname>
  falsy "$PS1_ONLYPROMPT" && truthy "$PS1_HOSTNAME" && \
    PS1+="@$bold\h$reset ";

  # <workingdirectory>
  falsy "$PS1_ONLYPROMPT" && if truthy "$PS1_DIRECTORY" || \
    [[ $PS1_DIRECTORY =~ full|relative ]]; then

    PS1+="$color"
    [[ $PS1_DIRECTORY =~ relative ]] && \
      PS1+="\W" || \
      PS1+="\w";

    # <git status>
    truthy "$PS1_GIT" && \
      PS1+="$reset$yellow"'$(__git_ps1 " %s" 2>/dev/null)'

    PS1+="$reset "
  fi

  # <kubernetes info>
  falsy "$PS1_ONLYPROMPT" && truthy "$PS1_KUBERNETES" && \
    PS1+="$reset$blue\$(kubectx -c)$reset:$green\$(kubens -c) "

  # <n background jobs> if != 0
  falsy "$PS1_ONLYPROMPT" && truthy "$PS1_JOBS" && {
    local j; j=$(_jobscounter); [[ $j -gt 0 ]] && \
    PS1+="${magenta}j${bold}$(_jobscounter)$reset"
  }

  # e<exit status> if != 0
  falsy "$PS1_ONLYPROMPT" && truthy "$PS1_STATUS" && \
    [[ $exitstatus != 0 ]] && PS1+="${red}e${bold}${exitstatus} "
  # these symbols were used for 'green' exit status indicators
  #local symbol='\[\342\234\]\224' # --> ✔
  #local symbol='\[\342\234\]\226' # --> ✖
  #local symbol='\[\342\234\]\227' # --> ✗
  #local symbol='\[\342\200\]\242' # --> •
  #local symbol='\[\342\246\]\201' # --> ⦁
  #local symbol='\[\342\236\]\244' # --> ➤
  #local symbol='\[\342\212\]\263' # --> ⊳
  #local symbol='\[\342\256\]\236' # --> ⮞
  #local symbol='\[\342\226\]\252' # --> ▪
  #local symbol='\[\342\235\]\261' # --> ❱

  # prompt symbol $/#
  PS1+="$reset$bold\\\$$reset "

  # line-continuation prompt
  PS2="$bold$yellow>$reset "

  # restore settings
  eval "$settings"

  # unset local functions
  unset -f _jobscounter

}

PROMPT_COMMAND="prompt_builder"

# If this is an xterm set the window title too
[[ $TERM =~ xterm*|rxvt*|Eterm|aterm|kterm|gnome* ]] && \
  PROMPT_COMMAND="${PROMPT_COMMAND}; "'printf "\033]0;%s@%s: %s\007" "$USER" "$HOSTNAME" "$PWD"'";"
