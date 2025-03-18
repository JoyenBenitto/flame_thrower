#!/bin/bash

# Check if expect is installed
if ! command -v expect &> /dev/null; then
    echo "Error: 'expect' utility is not installed. It's needed to handle OpenSTA interactive prompts."
    echo "Please install it with: sudo apt-get install expect"
    exit 1
fi

# Create a temporary expect script
cat > /tmp/sta_expect.exp << 'EOL'
#!/usr/bin/expect -f

# Get arguments
set sta_bin [lindex $argv 0]
set tcl_script [lindex $argv 1]
set timeout 300

# Spawn the OpenSTA process
spawn $sta_bin $tcl_script

# Handle any prompts that might come up
expect {
    -re ".*>" {
        send "exit\r"
        exp_continue
    }
    timeout {
        puts "OpenSTA timed out after 5 minutes."
        exit 1
    }
    eof
}

wait
catch {close}
exit 0
EOL

chmod +x /tmp/sta_expect.exp

# Run the expect script
/tmp/sta_expect.exp "$1" "$2" | tee "$3"

# Clean up
rm /tmp/sta_expect.exp
