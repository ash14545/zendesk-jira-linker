#!/bin/bash

# Check if the URL is provided
if [ $# -ne 1 ]; then
  echo "Usage: $0 <URL>"
  exit 1
fi

URL=$1

# Function to fetch data from a given URL
fetch_data() {
  local url=$1
  curl -s -X GET "$url" -u "$ZENDESK_EMAIL/token:$ZENDESK_API_TOKEN"
}

# Fetch data from the API
fetch_data "$URL"
