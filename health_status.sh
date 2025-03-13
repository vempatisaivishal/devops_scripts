#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if required commands exist
if ! command_exists vmstat || ! command_exists free || ! command_exists df; then
    echo "Error: Required commands (vmstat, free, or df) not found. Please install procps and coreutils."
    exit 1
fi

# Get CPU usage (using vmstat, taking average of last second)
# 100 - idle percentage gives us the usage percentage
cpu_usage=$(vmstat 1 2 | tail -1 | awk '{print 100 - $15}')

# Get memory usage percentage
memory_usage=$(free | grep Mem | awk '{print ($3/$2) * 100}')

# Get disk space usage percentage (root partition)
disk_usage=$(df -h / | tail -1 | awk '{print substr($5, 1, length($5)-1)}')

# Threshold (60%)
threshold=60

# Flag to track health status
healthy=true
explain_mode=false

# Check if explain argument is provided
if [ "$1" = "explain" ]; then
    explain_mode=true
fi

# Health check logic
if (( $(echo "$cpu_usage > $threshold" | bc -l) )); then
    healthy=false
fi

if (( $(echo "$memory_usage > $threshold" | bc -l) )); then
    healthy=false
fi

if (( $(echo "$disk_usage > $threshold" | bc -l) )); then
    healthy=false
fi

# Output results
if [ "$healthy" = true ]; then
    echo "VM Health Status: Healthy"
else
    echo "VM Health Status: Not Healthy"
fi

# Explanation if requested
if [ "$explain_mode" = true ]; then
    echo -e "\nDetailed Analysis:"
    echo "CPU Usage: ${cpu_usage}%"
    if (( $(echo "$cpu_usage > $threshold" | bc -l) )); then
        echo "  - CPU usage exceeds ${threshold}% threshold"
    else
        echo "  - CPU usage is within healthy range"
    fi
    
    echo "Memory Usage: ${memory_usage}%"
    if (( $(echo "$memory_usage > $threshold" | bc -l) )); then
        echo "  - Memory usage exceeds ${threshold}% threshold"
    else
        echo "  - Memory usage is within healthy range"
    fi
    
    echo "Disk Usage: ${disk_usage}%"
    if (( $(echo "$disk_usage > $threshold" | bc -l) )); then
        echo "  - Disk usage exceeds ${threshold}% threshold"
    else
        echo "  - Disk usage is within healthy range"
    fi
fi

exit 0
