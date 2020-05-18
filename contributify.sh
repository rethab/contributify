#!/bin/bash

set -e

CMD=$1

# disable unused variables
# shellcheck disable=SC2034
{
  # letter are defined as indices in the calendar, like so:
  # 0  7 14 ..
  # 1  8 15
  # 2  9 16
  # 3 10 17
  # ..
  E=(0 1 2 3 4 5 6 7 10 13 14 17 20 21 24 27 28 34 35 41)
  H=(0 1 2 3 4 5 6 10 17 24 31 35 36 37 38 39 40 41)
  L=(0 1 2 3 4 5 6 13 20 27 34 41)
  O=(0 1 2 3 4 5 6 7 13 14 20 21 27 28 34 35 36 37 38 39 40 41)
  R=(0 1 2 3 4 5 6 7 10 14 17 21 23 25 28 30 32 36 40 41)

  # visual hints to extend the letters :)
  #
  #    x    xxxx  xxxxxx xxxxxxx  xxxx   x     x x x        
  #   x x   x   x x      x       x    x  x     x x x       
  #  x   x  x   x x      x       x       x     x x x       
  # x     x xxxx  xxxx   xxxx    x       xxxxxxx x x            
  # xxxxxxx x   x x      x       x  xxx  x     x x x       
  # x     x x   x x      x       x    x  x     x x x       
  # x     x xxxx  xxxxxx x        xxxx   x     x x xxxxxxx 
  # 
  # xxxxx  xxxxxxx  xxxxxxx x     x x     x 
  # x    x    x     x     x x     x x     x 
  # x  xx     x     x     x x     x  x   x  
  # xxx       x     x     x x     x  x   x  
  # x  xx     x     x     x x     x  x   x  
  # x    x    x     x     x x     x  x x x  
  # x    x    x     xxxxxxx xxxxxxx   x x   
}

# github shows 366 days in 2020 (leap). not sure what they show in non-leap years
one_year_ago=$(date --date="$(date +%Y-%m-%d) - 365 days" +%Y-%m-%d)

all_letters=()
set_all_letters() {
  local text="$1"
  local idx=0
  while [ $idx -lt ${#text} ]; do
    local letter=${text:$idx:1}
    if [ -z "${!letter}" ]; then
      printf "Letter '%s' does not exist. Please extend this script :)\n" "${letter}"
      exit 1
    fi

    arr="${letter}[@]"
    for i in "${!arr}"; do
      # 7 boxes for one char (monospace) + 1 box margin = 8
      all_letters+=($((i + idx * 8 * 7)));
    done
    idx=$((idx + 1))
  done
}

# from: https://stackoverflow.com/a/8574392/1080523
in_arr() {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

create_commit() {
  local repo=$1
  local idx=$2
  commit_date=$(date --date="${one_year_ago} + ${idx} days" +%Y-%m-%dT09:00:00Z)
  git -C "$repo" commit --quiet --allow-empty --message "contributify" --date "$commit_date"
  printf "Create commit at date %s\n" "$commit_date"
}

run() {
  local dry=$1
  local text=$2
  set_all_letters "$text"
  local repo=$3

  for row in $(seq 0 6);
  do
    for col in $(seq 0 52);
      do
        idx=$((col * 7 + row))
        if in_arr "$idx" "${all_letters[@]}"; then
          if "$dry" = true; then
            printf "x"
          else
            create_commit "$repo" $idx
          fi
        elif "$dry" = false; then
          printf " "
        fi
      done
    if "$dry" = true; then
      printf "\n"
    fi
  done
}

show_help() {
  printf "Contributify (c) 2020, Reto Habluetzel\n"
  printf "\n"
  printf "Creates commits in a git repo such that Github shows a certain text in your contributions calendar\n"
  printf "\n"
  printf "%s <command> [<args>]\n" "$0"
  printf "\n"
  printf "Available commands\n"
  printf " help: shows this help\n"
  printf " dry-run TEXT: prints TEXT on the terminal\n"
  printf " run --repo REPO TEXT: creates commits in REPO\n"
  printf "\n"
  printf "\n"
  printf "Eg. ./contributify.sh --repo /tmp/testrepo HELLO\n"
}


text=""
repo=""
case $CMD in
  help)    show_help ;;
  dry-run)
    text=$2
    run true "$text"
    ;;
  run)
    [[ "$2" == "--repo" ]] || { printf "second param must be --repo. See help\n"; exit 1; } && { repo=$3; }
    git -C "$repo" status  >/dev/null 2>&1 || { printf "'%s' is not a git repository\n" "$repo"; exit 1; }
    text=$4
    run false "$text" "$repo"
    ;;
  *)
   echo "unknown command.."
   show_help 
   exit 1
   ;;
esac




