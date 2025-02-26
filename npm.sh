#!/bin/bash

# Function to check if npm is installed
check_npm() {
    if ! command -v npm &>/dev/null; then
        echo "npm is not installed. Please install Node.js which includes npm."
        exit 1
    else
        echo "npm is already installed."
    fi
}

# Function to clean and reinstall dependencies
clean_and_install() {
    local run_number=$1
    echo "Run #$run_number: Cleaning up and reinstalling..."

    # Print the current cache size
    echo "Current npm cache size:"
    npm cache verify --silent || echo "Unable to verify cache size"

    # Purge the npm cache
    echo "Purging npm cache..."
    npm cache clean --force

    # Verify the cache is empty
    echo "Verifying npm cache is cleared:"
    npm cache verify

    echo "npm cache purge complete!"

    # Clear all dependencies
    echo "Clearing dependencies..."
    find . -name "node_modules" -type d -prune -exec rm -rf '{}' +
}

# Function to display results in a table
display_results() {
    # local -n results_array=$1
    local results_array=("$@") # Store all arguments in an array
    echo "============================================"
    echo "| Run # | Installation Time (seconds) |"
    echo "============================================"
    for ((i = 0; i < ${#results_array[@]}; i++)); do
        printf "| %-5s | %-28s |\n" "$((i + 1))" "${results_array[$i]}"
    done
    echo "============================================"

    # Calculate and display statistics
    # Calculate and display statistics
    total=0
    min=${results_array[0]}
    max=${results_array[0]}

    for time in "${results_array[@]}"; do
        total=$(echo "$total + $time" | bc)
        if (($(echo "$time < $min" | bc -l))); then
            min=$time
        fi
        if (($(echo "$time > $max" | bc -l))); then
            max=$time
        fi
    done

    avg=$(echo "scale=2; $total / ${#results_array[@]}" | bc)
    echo "Average installation time: $avg seconds"
    echo "Minimum installation time: $min seconds"
    echo "Maximum installation time: $max seconds"
}

# Main script
# Check for bc (used for floating-point arithmetic)
if ! command -v bc &>/dev/null; then
    echo "The 'bc' utility is required but not installed. Please install it first."
    exit 1
fi

echo "===== NPM Installation Benchmark ====="
echo "This script will run the installation process 5 times and measure performance."
echo "A 5-second pause will be added between each run."

# Run the benchmarks
declare -a results
check_npm

for run in {1..2}; do
    echo "------------------------------------------"
    # Execute the function directly and capture output
    clean_and_install "$run"

    # Run a fresh install and measure time
    echo "Installing dependencies..."

    # Capture start time
    start_time=$(date +%s.%N)

    # Run npm install
    npm install

    # Capture end time
    end_time=$(date +%s.%N)

    # Calculate elapsed time
    elapsed=$(echo "$end_time - $start_time" | bc)

    # Format the result to 2 decimal places
    time_taken=$(echo "$elapsed" | awk '{printf "%.2f", $0}')

    results[$((run - 1))]=$time_taken

    echo " Start time: $start_time"
    echo " End time: $end_time"
    echo " Elapsed time: $elapsed"
    echo "Run #$run completed in $time_taken seconds"

    # Add a 5-second pause between runs (except after the last one)
    if [ $run -lt 2 ]; then
        echo "Pausing for 5 seconds before next run..."
        sleep 5
    fi

    echo "------------------------------------------"
done

# Display the results table
display_results "${results[@]}"
echo "Benchmark completed."
