#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Initialize the results JSON file
results_file="jira_ids_results.json"
echo "{\"tickets\": [" >"$results_file"

# Checkpoint file to store last processed ticket ID
checkpoint_file="checkpoint.txt"
last_ticket_id=""

# Read last processed ticket ID from checkpoint file, if exists
if [ -f "$checkpoint_file" ]; then
    last_ticket_id=$(cat "$checkpoint_file")
    echo "Resuming from ticket ID: $last_ticket_id"
fi

# Function to fetch Zendesk ticket details and comments
fetch_ticket_details() {
    local ticket_id="$1"

    # Fetch ticket details
    ticket_info=$(curl -s -u "$EMAIL/token:$API_TOKEN" "https://$SUBDOMAIN.zendesk.com/api/v2/tickets/$ticket_id.json")

    # Extract ticket fields
    echo "$ticket_info" | jq -r '.ticket'
    url=$(echo "$ticket_info" | jq -r '.ticket.url')
    created_at=$(echo "$ticket_info" | jq -r '.ticket.created_at')
    status=$(echo "$ticket_info" | jq -r '.ticket.status')

    # Format subject to handle special characters like double quotes
    subject=$(echo "$ticket_info" | jq -r '.ticket.subject' | jq -sR .)

    description=$(echo "$ticket_info" | jq -r '.ticket.description' | jq -sR .)

    priority=$(echo "$ticket_info" | jq -r '.ticket.custom_fields[] | select(.id == 360013245251) | .value')

    tags=$(echo "$ticket_info" | jq -r '.ticket.tags')
    custom_fields=$(echo "$ticket_info" | jq -c '.ticket.custom_fields')

    # Fetch comments and extract unique Jira IDs
    comments=$(curl -s -u "$EMAIL/token:$API_TOKEN" "https://$SUBDOMAIN.zendesk.com/api/v2/tickets/$ticket_id/comments.json" | jq -r '.comments[].body')
    jira_ids=()

    while read -r comment; do
        jira_id=$(echo "$comment" | grep -oE "$JIRA_PATTERN" | head -n 1)
        if [ -n "$jira_id" ] && ! [[ " ${jira_ids[@]} " =~ " $jira_id " ]]; then
            echo "Found Jira ID: $jira_id in ticket $ticket_id"
            jira_ids+=("$jira_id")
        fi
    done <<<"$comments"

    # Prepare JSON structure for the ticket
    jira_ids_json=$(printf '"%s",' "${jira_ids[@]}" | sed 's/,$//')
    ticket_json="{\"jira_ids\": [ $jira_ids_json ], \"url\": \"$url\", \"id\": \"$ticket_id\", \"created_at\": \"$created_at\", \"status\": \"$status\", \"subject\": $subject, \"description\": $description, \"priority\": \"$priority\", \"tags\": $tags, \"custom_fields\": $custom_fields},"

    echo "$ticket_json" >>"$results_file"

    # Update checkpoint file with current ticket ID
    echo "$ticket_id" > "$checkpoint_file"
}

# Function to fetch Zendesk tickets based on status and process each ticket
get_tickets_with_status() {
    local page_url="$1"
    local tickets

    response=$(curl -s -u "$EMAIL/token:$API_TOKEN" "$page_url")
    tickets=$(echo "$response" | jq -c '.results[]')

    if [ -z "$tickets" ]; then
        echo "No tickets found for URL: $page_url"
        return
    fi

    while IFS= read -r ticket_info; do
        ticket_id=$(echo "$ticket_info" | jq -r '.id')

        # Skip tickets until we reach the last processed ticket ID
        if [ "$ticket_id" = "$last_ticket_id" ]; then
            last_ticket_id=""
        elif [ -n "$last_ticket_id" ]; then
            continue
        fi

        echo "Processing ticket ID: $ticket_id"
        fetch_ticket_details "$ticket_id"
        sleep 1 # Add delay to avoid rate limiting
    done <<<"$tickets"

    next_page=$(echo "$response" | jq -r '.next_page')
    if [ "$next_page" != "null" ]; then
        get_tickets_with_status "$next_page"
    fi
}

# Paginate through Zendesk search results
initial_url="https://$SUBDOMAIN.zendesk.com/api/v2/search.json?query=status:$STATUS"
get_tickets_with_status "$initial_url"

# Finalize the results JSON file
sed -i '$ s/,$//' "$results_file"
echo "]}" >>"$results_file"

echo "Processing complete. Results saved in $results_file"
