# zendesk-jira-linker

This project should get all zendesk tickets on hold with a linked jira in statuses [need more info, done, closed]

Workflow:

1. fetch all zendesk tickets with linked jira.

2. use parallels for each ticket to get jira status. store results locally (for debugging/testing)

3. ??

4. profit

5. stonks :>

Requirements:

* Zendesk API
* Jira API
* homebrew
* parallel

Notes:

* use parallels to make process faster

How to set up .env:

SUBDOMAIN=YOUR-SUBDOMAIN
EMAIL=YOUR-EMAIL
API_TOKEN=YOUR-API-TOKEN