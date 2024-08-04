#!/bin/bash

# Load environment variables from the .env file in the same directory
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

# Check for required dependencies
for cmd in jq parallel; do
  if ! command -v $cmd &> /dev/null; then
    echo "$cmd is not installed. Please install it using apt-get. e.g., sudo apt-get install $cmd"
    exit 1
  fi
done

# Make sure fetch-tickets.sh and process-tickets.sh are executable
chmod +x ./api/fetch-tickets.sh
chmod +x ./api/process-tickets.sh
chmod +x ./api/process-ticket.sh

# Create directories for results and tmp if they do not exist
results_dir="results"
tmp_dir="tmp"
mkdir -p "$results_dir" "$tmp_dir"

# Initialize variables
next_url="https://$ZENDESK_SUBDOMAIN.zendesk.com/api/v2/jira/links.json"
page_number=1
all_results="[]"

# Fetch results in pages
while [ -n "$next_url" ]; do
  echo "Fetching page $page_number..."

  # Fetch data from the API
  response=$(./api/fetch-tickets.sh "$next_url")
  
  # Check if the request was successful
  if [ $? -ne 0 ]; then
    echo "Error fetching data from Zendesk API"
    exit 1
  fi

  # Extract the links array and append to all_results
  results=$(echo "$response" | jq '.links // []')
  all_results=$(echo "$all_results" | jq -c '. + '"$results")
  
  # Print a checkpoint message
  echo "Fetched page $page_number"

  # Extract the after_cursor URL for the next page
  next_page=$(echo "$response" | jq -r '.meta.after_cursor // empty')

  # URL encode the next_page URL if it exists
  if [ -n "$next_page" ]; then
    next_url=$(echo "$next_page" | sed 's/\[/%5B/g; s/\]/%5D/g')
  else
    next_url=""
  fi

  # Increment page number
  ((page_number++))
done

# Save all results to a file with timestamp
timestamp=$(date +"%Y%m%d%H%M%S") # this will be used for final product
output_file="$results_dir/results.json" # fetched data here
echo "$all_results" | jq '.' > "$output_file"

# Print the final results
echo "All results from Zendesk API saved to $output_file"
echo "Total pages fetched: $((page_number - 1))"

# Split tickets into batches of 50 and save them in tmp
echo "Processing batches..."

# Create a temporary directory if it doesn't exist
mkdir -p tmp

# Filter and split the data into batches
echo "$all_results" | jq -c '. | map({ticket_id, issue_key}) | .[]' | split -l 50 -a 3 -d - tmp/batch_

# Rename split files to add .json extension
for file in tmp/batch_*; do
  mv "$file" "${file}.json"
done

# Process each batch using parallel
ls tmp/batch_*.json | parallel --colsep ' ' ./api/process-tickets.sh

# Print completion message
echo "All batch processing has been completed."

rm -rf tmp