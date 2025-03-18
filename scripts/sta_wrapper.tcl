# Simple wrapper script to source the main timing analysis script and then exit

# First, source the actual timing analysis script
source [lindex $argv 0]

# Then force exit
puts "Forcing exit from OpenSTA..."
exit 0
