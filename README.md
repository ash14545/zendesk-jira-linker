# zendesk-jira-linker

## Overview

This Bash script fetches Zendesk ticket details, including Jira IDs from comments, and stores the results in a JSON file.

## Requirements

- Bash (version 4.0 or higher)
- `curl` command-line tool
- `jq` JSON processor (install via package manager)

## Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/your-repo.git
   cd your-repo
   ```

2. **Set up environment variables:**
   Create a `.env` file in the project root with the following variables:
   ```plaintext
   SUBDOMAIN="your-zendesk-subdomain"
   EMAIL="your-email@example.com"
   API_TOKEN="your-zendesk-api-token"
   STATUS="hold"
   JIRA_PATTERN="(PROJECT NAME|PROJECT NAME|PROJECT NAME)-[0-9]+"
   ```

3. **Install dependencies:**
   Ensure `jq` is installed:
   ```bash
   # Example for Debian/Ubuntu
   sudo apt-get update
   sudo apt-get install jq
   ```

4. **Run the script:**
   ```bash
   ./fetch_zendesk_tickets.sh
   ```

## Functionality

- **Fetching Tickets:** Queries Zendesk API for tickets with a specified status (`$STATUS`).
- **Processing:** Retrieves ticket details and extracts unique Jira IDs from comments.
- **Output:** Saves results to `jira_ids_results.json` in a structured JSON format.

## Checkpoint Mechanism

- **Resuming from Interruptions:** The script uses a `checkpoint.txt` file to resume processing from the last successfully fetched ticket ID in case of interruptions or failures.

## Notes

- Adjust the script and environment variables (`SUBDOMAIN`, `EMAIL`, `API_TOKEN`, `STATUS`, `JIRA_PATTERN`) to match your Zendesk setup and requirements.
- Ensure `curl` commands are permitted by firewall rules and Zendesk API access settings.
- Handle errors and exceptions as needed for your specific use case.
