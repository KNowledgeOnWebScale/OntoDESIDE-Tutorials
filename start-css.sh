#!/bin/bash
# Execute this script to (re)start the CSS's in this project (no Docker)
# Assumptions:
#   - this script is run from the repository root
#   - in case of option -r: this script and stop-csss.sh ran before, and the ./local-run dir hasn't been deleted
# Parameters:
#    - -r|--restart: restart the CSS's with existing pod contents

set -euo pipefail

# Initialize RESTART variable
RESTART=false

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -r|--restart) RESTART=true ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Display the status of RESTART variable
if [ "$RESTART" = true ]; then
    echo "Restarting CSS's with existing pod contents"
else
    echo "Starting CSS's with all new pod contents"
fi

# this directory should be git-ignored
LOCAL_RUN_DIR=./local-run
if [ "$RESTART" = false ]; then
  rm -rf $LOCAL_RUN_DIR
  mkdir -p $LOCAL_RUN_DIR
fi

WAITING_COUNT=1

# Start one CSS in the background as a separate process
# Parameters
# - $1: the name of the CSS (e.g. css0)
function start_css {
    local CSSX="$1"

    local ROOT_DIR=$LOCAL_RUN_DIR/data/$CSSX
    local CONFIG_DIR=$LOCAL_RUN_DIR/config/$CSSX
    if [ "$RESTART" = false ]; then
      rm -rf $ROOT_DIR
      mkdir -p $ROOT_DIR
      rm -rf $CONFIG_DIR
      mkdir -p $CONFIG_DIR
    fi

    # Name of specific files
    local CONFIG_FILE=$CONFIG_DIR/$CSSX.json
    local LOG_FILE=$LOCAL_RUN_DIR/$CSSX.log
    local PID_FILE=$LOCAL_RUN_DIR/$CSSX.pid

    # Start CSSX with its specific configuration
    case "$CSSX" in
        "css12")
            local PORT=3012
            ;;
        *)
            echo "Unknown CSSX: $CSSX"
            exit 2
            ;;
    esac

    if [ "$RESTART" = false ]; then
      # Make a specific config file
      cp ./css-config/config.json $CONFIG_FILE
      # And... go as a background process
      nohup npx community-solid-server --port $PORT --config $CONFIG_FILE --seedConfig ./css-config/css-users.json --rootFilePath $ROOT_DIR > $LOG_FILE 2>&1 &
    else  
      # Reuse existing specific config file and go as a background process (no --seedConfig option)
      nohup npx community-solid-server --port $PORT --config $CONFIG_FILE                                                    --rootFilePath $ROOT_DIR > $LOG_FILE 2>&1 &
    fi
    # Remember the port and not the process id, because killing based on the process id does not work for node child processes
    echo "$PORT" > $PID_FILE
    echo "Started $CSSX on port $PORT."
}

# Check whether one CSS is listening
# Parameters
# - $1: the name of the file containing the port the CSS is listening to
function check_css {
    local PID_FILE="$1"
    local PORT=$(< $PID_FILE)
    if ! curl http://localhost:$PORT > /dev/null 2>&1 ; then
        echo "Waiting for $PORT to start listening..."
        WAITING_COUNT=$((WAITING_COUNT+1))
    fi
}

start_css css12

while [[ $WAITING_COUNT > 0 ]] ; do
    WAITING_COUNT=0
    for f in ./local-run/*.pid ; do
        check_css $f
    done
    if [[ $WAITING_COUNT > 0 ]] ; then
        sleep 5
    fi
done
echo "All CSS's listening."
