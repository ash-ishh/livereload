#!/usr/bin/env bash
# Author: <Ash-Ishh..>
set -e

install_inotify() {
  YUM_CMD=$(command -v yum)
  APT_GET_CMD=$(command -v apt-get)
  PACMAN_CMD=$(command -v pacman) 

  if [[ ! -z $YUM_CMD ]]; then
    sudo yum install inotify-tools
  elif [[ ! -z $APT_GET_CMD ]]; then
    sudo apt-get install inotify-tools
  elif [[ ! -z $PACMAN_CMD ]]; then
    sudo pacman -S inotify-tools
  fi
}

usage() {
  echo
  echo "Usage: $0 -d DIRECTORY -c COMMAND"
  echo "Execute COMMAND and restart it on changes in DIRECTORY."
  echo
  echo "-h, --help              display help and exit"
  exit 2
}

watch_files() {
  # TODO: take extension from args
  inotifywait -q -m -r $DIRECTORY -e CLOSE_WRITE --exclude '[^p].$|[^y]$' | while read -r path action file;
  do
    pkill -f "^$COMMAND"
    run_command
  done
}

run_command() {
  sh -c "$COMMAND" > /tmp/hotreload
}

trap ctrl_c INT
function ctrl_c() {
  echo "Killing background processes"
  pkill -e "$COMMAND"
  #TODO: kill process spawned by this script only
  pkill inotifywait
  rm /tmp/hotreload
}

# getopts stuff
unset DIRECTORY COMMAND
while getopts 'd:c:-help' option
do
  case $option in
    d) DIRECTORY=$OPTARG ;;
    c) COMMAND=$OPTARG ;;
    help) usage;;
  esac
done

[ -z "$DIRECTORY" ] && usage
[ -z "$COMMAND" ] && usage 

# check if inotify is installed 
if ! [ -x "$(command -v inotifywait)" ]; then
  echo 'inotify is not installed.' >&2
  echo -n 'Do you want to install inotify (y/n)? '
  read answer
  if [ "$answer" != "${answer#[Yy]}" ] ;then
    install_inotify
  else
    exit
  fi
fi

watch_files &
run_command &

tail -F /tmp/hotreload
