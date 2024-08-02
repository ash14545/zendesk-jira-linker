#!/bin/bash

# Check if the batch file is provided
if [ $# -ne 1 ]; then
  echo "Usage: $0 <batch_file>"
  exit 1
fi

batch_file=$1

# Check if the file exists
if [ ! -f "$batch_file" ]; then
  echo "File not found: $batch_file"
  exit 1
fi

# Output the contents of the batch file
echo "Contents of $batch_file:"
cat "$batch_file"
