#!/bin/bash

# Check if the ticket_id and issue_key are provided
if [ $# -ne 2 ]; then
  echo "Usage: $0 <ticket_id> <issue_key>"
  exit 1
fi

ticket_id=$1
issue_key=$2

# Call process-ticket.sh with the provided ticket_id and issue_key
./zendesk-api/process-ticket.sh "$ticket_id" "$issue_key"
