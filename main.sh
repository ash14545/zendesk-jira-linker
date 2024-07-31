#!/bin/bash

# Dependencies
# Check for parallel dependency
if ! command -v parallel &> /dev/null; then
  echo "GNU Parallel is not installed. Please install it with Homebrew: brew install parallel"
  exit 1
fi

# Fetch all Zendesk tickets with a linked Jira ticket
cd zendesk-api
./fetch-tickets.sh