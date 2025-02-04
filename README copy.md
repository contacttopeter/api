# Automated Dataset Downloader and HTML Display

## Overview
This project automates the download of exchange rate data from the Coinbase API, extracts relevant information, and displays it in an HTML table. The data is stored in Google Cloud Storage (GCS) and can be accessed publicly.

## Setup
1. Clone this repository.
2. Use Terraform to provision Google Cloud resources (GCS bucket).
3. Dockerize the application and deploy using GitHub Actions.

## Features
- **Automated data fetching**: Scheduled every hour using GitHub Actions.
- **Data storage**: All data stored in GCS.
- **HTML Display**: View the latest exchange rates for CZK in an HTML table.

## Future Considerations
- Handle different types of API errors.
- Optimize the script to support more currencies.
- Add more advanced templating for HTML generation.