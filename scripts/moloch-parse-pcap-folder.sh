#!/bin/bash
# argument parsing
TAG=""
PCAPDIR="/data/pcap"
pcapdir_set=false

help() {
  usage
  echo
  echo "  -d PCAPDIR    The directory where the .pcap files are stored."
  echo "  -t TAG        Extra tag to add to all packages. Multiple tags can be separated with a comma, e.g. '-t foo,bar'"
  echo
  exit 0
}
usage() {
  echo "Usage: $0 [ -d PCAPDIR ] [ -t TAG ]" 1>&2
}
exit_abnormal() {
  usage
  exit 1
}
while getopts ":d:t:h" options; do
  case "${options}" in
    d)
      PCAPDIR=${OPTARG}
      if [ ! -d "$PCAPDIR" ]; then
        echo "ERROR: The directory '$PCAPDIR' does not exist!" 1>&2
        exit_abnormal
      fi

      pcapdir_set=true
      ;;
    t)
      IFS=','
      TAG=($OPTARG)
      unset IFS
      ;;
    :)
      echo "Error: -${OPTARG} requires an argument."
      exit_abnormal
      ;;
    h)
      help
      ;;
    *)
      exit_abnormal
      ;;
  esac
done


# check if the default pcap directory should be used
if [ "$pcapdir_set" = false ]; then
  echo "You didn't specify a PCAP directory. The default directory '$PCAPDIR' will be used."
  read -r -p "Do you want to continue? Y/[N] " response
  case "$response" in
    [yY][eE][sS]|[yY])
      # continue after
      ;;
    *)
      echo "Aborting..."
      exit 0
      ;;
  esac
fi


# process the tags
tags_cmd=""
for t in ${TAG[@]}; do
  tags_cmd="$tags_cmd -t $t"
done


# the command string
CMD_STRING="find $PCAPDIR -name '*.pcap*' -type f -exec $MOLOCHDIR/bin/moloch-capture -c $MOLOCHDIR/etc/config.ini -r '{}'$tags_cmd \;"

# execute the command
eval $CMD_STRING

