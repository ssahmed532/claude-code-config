#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract basic information
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
model=$(echo "$input" | jq -r '.model.display_name')
transcript_path=$(echo "$input" | jq -r '.transcript_path')

# ANSI color codes (dimmed for status line display)
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
MAGENTA='\033[0;35m'
YELLOW='\033[0;33m'
RESET='\033[0m'

# Get short directory name
short_dir=$(basename "$cwd")

# Get git branch if in a git repository (skip optional locks for performance)
git_branch=""
git_color=""
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
    branch_name=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
    if [ -n "$branch_name" ]; then
        # Check if repo is clean
        if git -C "$cwd" --no-optional-locks diff --quiet 2>/dev/null && \
           git -C "$cwd" --no-optional-locks diff --cached --quiet 2>/dev/null; then
            git_color="$GREEN"
        else
            git_color="$YELLOW"
        fi
        git_branch=$(printf " ${git_color}[%s]${RESET}" "$branch_name")
    fi
fi

# Calculate context usage percentage
remaining_pct=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
context_info=""
if [ -n "$remaining_pct" ]; then
    remaining_pct=$(printf "%.0f" "$remaining_pct")
    context_info=$(printf " ${MAGENTA}Context: %s%%${RESET}" "$remaining_pct")
fi

# Calculate cost
total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens')
total_output=$(echo "$input" | jq -r '.context_window.total_output_tokens')
cost=""
if [ "$total_input" != "null" ] && [ "$total_output" != "null" ]; then
    input_cost=$(echo "scale=4; $total_input * 3 / 1000000" | bc)
    output_cost=$(echo "scale=4; $total_output * 15 / 1000000" | bc)
    total_cost=$(echo "scale=2; $input_cost + $output_cost" | bc)
    cost=$(printf " | Cost: \$%s" "$total_cost")
fi

# Calculate session duration
duration=""
if [ -f "$transcript_path" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        start_time=$(stat -f %B "$transcript_path" 2>/dev/null)
    else
        start_time=$(stat -c %Y "$transcript_path" 2>/dev/null)
    fi

    if [ -n "$start_time" ]; then
        current_time=$(date +%s)
        elapsed=$((current_time - start_time))

        hours=$((elapsed / 3600))
        minutes=$(((elapsed % 3600) / 60))
        seconds=$((elapsed % 60))

        if [ $hours -gt 0 ]; then
            duration=$(printf " | %dh %dm" $hours $minutes)
        elif [ $minutes -gt 0 ]; then
            duration=$(printf " | %dm %ds" $minutes $seconds)
        else
            duration=$(printf " | %ds" $seconds)
        fi
    fi
fi

# Build and output the status line with colors
printf "${BLUE}%s${RESET}%s | ${CYAN}%s${RESET}%s%s%s" "$short_dir" "$git_branch" "$model" "$context_info" "$cost" "$duration"
