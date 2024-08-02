#!/bin/bash

# Read the batch data from stdin
batch=$(cat)

# Process each ticket in the batch
echo "$batch" | jq -c '.[]' | while read ticket; do
    ticket_id=$(echo "$ticket" | jq -r '.ticket_id')
    issue_key=$(echo "$ticket" | jq -r '.issue_key')

    # Call process-ticket.sh with the ticket_id and issue_key
    ./api/process-ticket.sh "$ticket_id" "$issue_key"
done
