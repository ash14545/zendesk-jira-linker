#!/bin/bash

# Load environment variables from the .env file in the same directory
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

# Check for required dependencies
for cmd in jq; do
  if ! command -v $cmd &> /dev/null; then
    echo "$cmd is not installed. Please install it using apt-get. e.g., sudo apt-get install $cmd"
    exit 1
  fi
done

# Make sure fetch-tickets.sh is executable
chmod +x ./zendesk-api/fetch-tickets.sh

# Create a directory for results if it does not exist
results_dir="results"
mkdir -p "$results_dir"

# Initialize variables
next_url="https://$ZENDESK_SUBDOMAIN.zendesk.com/api/v2/jira/links.json"
page_number=1
all_results="[]"

# Fetch results in pages
while [ -n "$next_url" ]; do
  echo "Fetching page $page_number..."

  # Fetch data from the API
  response=$(./zendesk-api/fetch-tickets.sh "$next_url")
  
  # Check if the request was successful
  if [ $? -ne 0 ]; then
    echo "Error fetching data from Zendesk API"
    exit 1
  fi

  # Extract the links array and append to all_results
  results=$(echo "$response" | jq '.links // []')
  all_results=$(echo "$all_results" | jq -c '. + '"$results")
  
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
timestamp=$(date +"%Y%m%d%H%M%S")
output_file="$results_dir/$timestamp.json"
echo "$all_results" | jq '.' > "$output_file"

# Print the final results
echo "All results from Zendesk API saved to $output_file"
echo "Total pages fetched: $((page_number - 1))"
