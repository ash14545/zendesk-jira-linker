#!/bin/bash

# Check if the batch file is provided
if [ $# -ne 1 ]; then
  echo "Usage: $0 <batch_file>"
  exit 1
fi

batch_file=$1

# Check if the batch file exists
if [ ! -f "$batch_file" ]; then
  echo "File not found: $batch_file"
  exit 1
fi

# Read ticket IDs and Jira issue keys from the batch file
ticket_ids=$(jq -r '.ticket_id' "$batch_file" | tr '\n' ',' | sed 's/,$//')
issue_keys=$(jq -r '.issue_key' "$batch_file" | tr '\n' ',' | sed 's/,$//')

# Check if ticket IDs and issue keys are not empty
if [ -z "$ticket_ids" ]; then
  echo "No ticket IDs found in the batch file"
  exit 1
fi

if [ -z "$issue_keys" ]; then
  echo "No issue keys found in the batch file"
  exit 1
fi

echo "Processing batches..."

# Fetch Zendesk ticket statuses
zendesk_url="https://$ZENDESK_SUBDOMAIN.zendesk.com/api/v2/tickets/show_many.json?ids=$ticket_ids"
response=$(curl -s -u "$ZENDESK_EMAIL/token:$ZENDESK_API_TOKEN" "$zendesk_url")

# Check if the response is valid JSON
if ! echo "$response" | jq . >/dev/null 2>&1; then
  echo "Invalid JSON response from Zendesk"
  exit 1
fi

# Extract and print ticket statuses
echo "Zendesk Ticket Statuses:"
echo "$response" | jq -r '.tickets[] | "\(.id): \(.status)"'

if [ -z "$issue_keys" ]; then
  echo "No issue keys found in the batch file"
else
  # Fetch Jira issue details using JQL
  jira_response=$(curl -s -u "$JIRA_USER:$JIRA_API_TOKEN" \
    "https://$JIRA_SUBDOMAIN.atlassian.net/rest/api/2/search?jql=issue%20IN%20($issue_keys)&fields=key,status")

  # Extract and print issue keys and statuses
  echo "$jira_response" | jq -r '.issues[] | "\(.key) \(.fields.status.name)"'
fi

echo "Batch processing completed."
