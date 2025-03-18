#!/bin/bash

# Wrapper script for OpenSTA to ensure it exits properly

# Command to run
CMD="$1"
TCL_SCRIPT="$2"
OUTPUT_LOG="$3"

# Create a named pipe for OpenSTA output
FIFO="/tmp/sta_fifo_$$.tmp"
mkfifo "$FIFO"

# Start a background process to timeout if needed
(sleep 300; echo "OpenSTA timeout reached, killing process"; pkill -f "$CMD $TCL_SCRIPT") &
TIMEOUT_PID=$!

# Run OpenSTA with output going to the pipe
"$CMD" "$TCL_SCRIPT" > "$FIFO" 2>&1 &
STA_PID=$!

# Read from the pipe into the log file
cat "$FIFO" | tee "$OUTPUT_LOG"

# Check if OpenSTA is still running
if ps -p $STA_PID > /dev/null; then
    echo "OpenSTA is still running, sending quit command..."
    # Try to send 'exit' to OpenSTA
    if command -v expect &> /dev/null; then
        expect -c "spawn -noecho sleep 1; send \"exit\r\"; expect eof" > /dev/null
    fi
    sleep 1
    
    # If still running, kill it
    if ps -p $STA_PID > /dev/null; then
        echo "Killing OpenSTA process ($STA_PID)"
        kill $STA_PID
    fi
fi

# Kill timeout process if it's still running
if ps -p $TIMEOUT_PID > /dev/null; then
    kill $TIMEOUT_PID
fi

# Clean up the pipe
rm "$FIFO"

# Return success
exit 0
