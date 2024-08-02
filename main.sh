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

# Save all results to a file with timestamp
timestamp=$(date +"%Y%m%d%H%M%S")
output_file="$results_dir/results.json"
echo "$all_results" | jq '.' > "$output_file"

# Print the final results
echo "All results from Zendesk API saved to $output_file"
echo "Total pages fetched: $((page_number - 1))"

# Create temporary directory for batch files
tmp_dir="tmp"
mkdir -p "$tmp_dir"

# Split tickets into batches
batch_size=50
total_tickets=$(cat "$output_file" | jq length)
batch_count=$(( (total_tickets + batch_size - 1) / batch_size ))

echo "Total tickets: $total_tickets"
echo "Total batches: $batch_count"

# Create an array to hold the batches
declare -a batches

# Generate batches
for ((i = 0; i < batch_count; i++)); do
  start_index=$((i * batch_size))
  end_index=$(((i + 1) * batch_size - 1))

  batch_file="$tmp_dir/batch_$i.json"
  jq -c ".[$start_index:$((end_index + 1))]" "$output_file" > "$batch_file"
  
  batches+=("$batch_file")
done

# Print each batch file content
echo "Processing batches..."
for batch in "${batches[@]}"; do
  echo "Batch file: $batch"
  jq -r '.[] | "\(.ticket_id) \(.issue_key)"' "$batch"
done

echo "Batch processing completed."
