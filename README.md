# zendesk-jira-linker

This project fetches ticket data from Zendesk, processes it, and synchronizes the relevant information with Jira issues. The script is designed to handle large volumes of tickets by splitting them into manageable batches and processing them in parallel.

## Prerequisites
Ensure you have the following dependencies installed:

* `jq`
* `parallel`
* `curl`

You can install them using:

```bash
sudo apt-get install jq parallel curl
```

## Project Structure

```arduino
├── main
├── .env
├── api
│   ├── fetch-tickets.sh
│   ├── process-tickets.sh
```

### Files

* **main.sh**: The main script that orchestrates the fetching and processing of tickets.
* **.env**: Environment variables for configuring the Zendesk and Jira API access.
* **api/fetch-tickets.sh**: Script to fetch ticket data from Zendesk.
* **api/process-tickets.sh**: Script to process fetched ticket data and synchronize it with Jira.

## Setup

1. **Clone the repository:**

```bash
Copy code
git clone <repository-url>
cd <repository-directory>
```

2. **Configure environment variables:**

Create a .env file in the project root with the following content:

```makefile
ZENDESK_SUBDOMAIN=your_zendesk_subdomain
ZENDESK_EMAIL=your_zendesk_email
ZENDESK_API_TOKEN=your_zendesk_api_token

JIRA_SUBDOMAIN=your_jira_subdomain
JIRA_USER=your_jira_user
JIRA_API_TOKEN=your_jira_api_token
```

3. **Make scripts executable:**

```bash
chmod +x main
chmod +x api/fetch-tickets.sh
chmod +x api/process-tickets.sh
```

## Usage

1. **Run the main script:**

```bash
./main
```

The script will:

* Load environment variables from the `.env` file.
* Check for required dependencies (`jq` and `parallel`).
* Ensure that the `fetch-tickets.sh` and `process-tickets.sh` scripts are executable.
* Create directories for results and temporary files if they do not exist.
* Fetch ticket data from Zendesk in pages and save the results to a file.
* Split the fetched data into batches of 50 and process each batch using `process-tickets.sh`.

## Cleaning Up

Temporary files used for batch processing are stored in a `tmp` directory and are cleaned up automatically at the end of the main script execution.
