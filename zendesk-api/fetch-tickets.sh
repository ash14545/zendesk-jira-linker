#!/bin/bash

# Load environment variables from the .env file in the root directory
if [ -f ../.env ]; then
  export $(grep -v '^#' ../.env | xargs)
fi

# Function to fetch data from a given URL
fetch_data() {
  local url=$1
  curl -s -X GET "$url" -u "$EMAIL/token:$API_TOKEN"
}

# Initialize the URL for the first page
next_url="https://$SUBDOMAIN.zendesk.com/api/v2/jira/links.json"
all_results="[]"

# Loop through all pages
while [ -n "$next_url" ]; do
  # Fetch data from the API
  response=$(fetch_data "$next_url")
  
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
done

# Save all results to a file
echo "$all_results" | jq '.' > fetched_results.json

# Print the final results
echo "All results from Zendesk API saved to fetched_results.json"
