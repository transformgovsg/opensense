#!/bin/bash

# Directory to check for old files, relative to the script's location
DIRECTORY="$(dirname "$0")/.files"

# Find and delete .csv and .txt files older than 5 minutes
find "$DIRECTORY" -type f \( -name "*.csv" -o -name "*.txt" \) -mmin +5 -exec rm -f {} \;

# Uncomment for debugging purposes
# echo "[PURGE_CSV_CRON] - $(date) - Deleted .csv and .txt files older than 5 minutes from $DIRECTORY" >> "$(dirname "$0")/cleanup.log"
