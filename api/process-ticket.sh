#!/bin/bash

# Check if the ticket_id and issue_key are provided
if [ $# -ne 2 ]; then
  echo "Usage: $0 <ticket_id> <issue_key>"
  exit 1
fi

ticket_id=$1
issue_key=$2

# Output the ticket_id and issue_key
echo "Ticket ID: $ticket_id"
echo "Issue Key: $issue_key"
