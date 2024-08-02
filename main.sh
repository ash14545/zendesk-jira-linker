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

# Save all results to a file
output_file="$results_dir/results.json"
echo "$all_results" | jq '.' > "$output_file"

# Split results into batches of 50 tickets each and send to process-tickets.sh
echo "Processing batches..."
batch_size=50
batches=()
total_tickets=$(echo "$all_results" | jq length)
for ((i=0; i<total_tickets; i+=batch_size)); do
  batch=$(echo "$all_results" | jq -c ".[$i:$((i + batch_size))] | map({ticket_id: .ticket_id, issue_key: .issue_key})")
  batches+=("$batch")
done

for batch in "${batches[@]}"; do
  echo "$batch" | ./api/process-tickets.sh
done

echo "Batch processing completed."
