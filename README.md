## Goal
This project demonstrates the ability to automate the deployment of a dockerized application using a **GitHub CI pipeline**.

## Infrastructure and Tools
- **Cloud compute** or a serverless equivalent.
- **Cloud storage**.
- **Docker** and preferred Docker image.
- **Terraform**.
- **Bash**.

## Task
1. Download regularly (e.g., daily/hourly) a dataset from a free data provider: [https://api.coinbase.com/v2/exchange-rates](https://api.coinbase.com/v2/exchange-rates).
2. Store the downloaded dataset to cloud storage.
3. Extract specific data from each dataset: **Current Exchange Rates (CZK)**.
4. Display all extracted data using a simple HTML page served from cloud storage.
5. Present the result in this **README file**.

## Instructions
- Use a well-known programming language to implement the application/script logic.
- Encapsulate the code and its dependencies inside a **Docker container**.
- Use **IaaC tools (Terraform)** to automate provisioning of cloud resources.
- Use **GitHub** to:
  - Store all source code, including this README.md to explain the approach and present the working result.
  - Use **GitHub Actions** to enforce coding practices and automate deployment to the cloud environment.
  - Document any encountered problems, todos, and future considerations.

## Repository Structure

/api-main
├── .github/workflows/      # CI/CD Pipelines (Terraform, Helm, Docker)
├── charts/api/             # Helm Chart for Kubernetes deployment
├── terraform/              # Terraform configurations for GCP infrastructure
├── Dockerfile              # Docker build configuration
├── README.md               # Project documentation
└── other config files...

## Infrastructure Details
### 1. Google Cloud Platform (GCP)
- Core infrastructure is managed using **Terraform**.
- Components include:
  - **GKE (Google Kubernetes Engine)** for running workloads.
  - **Cloud Storage** for storing artifacts.
  - **Cloud SQL / Databases** (if applicable).
  - **Cloud Armor** for security.

### 2. Kubernetes Deployments
- Managed using **Helm**.
- Helm chart located under `charts/api/`.
- Manages API, services, ConfigMaps, and secrets.

### 3. CI/CD Pipeline
The deployment pipeline is automated via **GitHub Actions** and is structured into:
- **Docker Build & Push:** Builds the API container and pushes it to the registry.
- **Helm Deployment:** Updates Kubernetes using the Helm chart.
- **Terraform Apply:** Updates GCP infrastructure as needed.
- **Scheduled Deployments:** Runs every hour for automated updates.

## Deployment Workflow
1. **Terraform Plan & Apply**:
   ```sh
   tf init
   tf plan
   tf apply

Docker Image Build & Push:

docker build -t your-repo/api:latest .
docker push your-repo/api:latest

Helm Chart Deployment:

helm upgrade --install api charts/api/ -f charts/api/values.yaml

Security & Networking

Ingress TLS is managed via Cloudflare and GCP.

Cloud Armor is used for DDoS protection.

RBAC is configured for Kubernetes security.

Monitoring & Logging

Metrics Collection: Uses Grafana/Agent and kube-state-metrics.

Log Aggregation: Integrated with GCP Logging.

Alerting: Configured in Grafana Cloud.

Contact

For any issues or contributions, please submit a pull request or open an issue in this repository.

manual steps:

- Create gcp Service Account for Terraform: 
gcloud iam service-accounts create terraform \
    --description="Terraform Service Account" \
    --display-name="Terraform"

- Grant owner role:
gcloud projects add-iam-policy-binding $(gcloud config get-value project) \
    --member="serviceAccount:terraform@$(gcloud config get-value project).iam.gserviceaccount.com" \
    --role="roles/owner"

-  Generate a Key for the Service Account
gcloud iam service-accounts keys create terraform-key.json \
    --iam-account=terraform@$(gcloud config get-value project).iam.gserviceaccount.com

- Take key and create API_GOOGLE_CREDENTIALS GitHub secret in web interface
cat terraform-key.json

- Add to docker credentials
Go to Secret manager and create "docker-credentials" secret with content of terraform-key.json

- Create GCP bucket
gcloud storage buckets create gs://api-bucket-default --location=us-central1

- Enable Uniform Bucket Level Access (UBLA) on your GCS bucket 
gcloud storage buckets update gs://api-bucket-default --uniform-bucket-level-access

- Enable Cloud Resource Manager API
gcloud services enable cloudresourcemanager.googleapis.com

- Generate PAT 
In your GitHub acount and create RUNNER_REGISTRATION_TOKEN ecret in web interface

API Deployment Infrastructure

This repository manages the infrastructure and deployment of the API running at https://api.prochazka.cc/. The deployment is automated using Terraform, Helm, Docker, and GitHub Actions.

Goal

This project demonstrates the ability to automate the deployment of a dockerized application using a GitHub CI pipeline.

Infrastructure and Tools

Cloud compute or a serverless equivalent.

Cloud storage.

Docker and preferred Docker image.

Terraform.

Bash.

Task

Download regularly (e.g., daily/hourly) a dataset from a free data provider: https://api.coinbase.com/v2/exchange-rates.

Store the downloaded dataset to cloud storage.

Extract specific data from each dataset: Current Exchange Rates (CZK).

Display all extracted data using a simple HTML page served from cloud storage.

Present the result in this README file.

Instructions

Use a well-known programming language to implement the application/script logic.

Encapsulate the code and its dependencies inside a Docker container.

Use IaaC tools (Terraform) to automate provisioning of cloud resources.

Use GitHub to:

Store all source code, including this README.md to explain the approach and present the working result.

Use GitHub Actions to enforce coding practices and automate deployment to the cloud environment.

Document any encountered problems, todos, and future considerations.

Repository Structure

/api-main
├── .github/workflows/      # CI/CD Pipelines (Terraform, Helm, Docker)
├── charts/api/             # Helm Chart for Kubernetes deployment
├── terraform/              # Terraform configurations for GCP infrastructure
├── Dockerfile              # Docker build configuration
├── README.md               # Project documentation
└── other config files...

Infrastructure Details

1. Google Cloud Platform (GCP)

Core infrastructure is managed using Terraform.

Components include:

GKE (Google Kubernetes Engine) for running workloads.

Cloud Storage for storing artifacts.

Cloud SQL / Databases (if applicable).

Cloud Armor for security.

2. Kubernetes Deployments

Managed using Helm.

Helm chart located under charts/api/.

Manages API, services, ConfigMaps, and secrets.

3. CI/CD Pipeline

The deployment pipeline is automated via GitHub Actions and is structured into:

Docker Build & Push: Builds the API container and pushes it to the registry.

Helm Deployment: Updates Kubernetes using the Helm chart.

Terraform Apply: Updates GCP infrastructure as needed.

Scheduled Deployments: Runs every hour for automated updates.

Deployment Workflow

Terraform Plan & Apply:

Terraform manages infrastructure updates.

Runs via terraform_apply.yaml in GitHub Actions.

Docker Image Build & Push:

Builds the Docker image and pushes it to the container registry.

Defined in web-build.yaml workflow.

Helm Chart Deployment:

Deploys Kubernetes workloads using Helm.

Managed in helm-build.yaml workflow.

How to Deploy Manually

1. Infrastructure Setup

tf init
tf plan
tf apply

2. Build & Push Docker Image

docker build -t your-repo/api:latest .
docker push your-repo/api:latest

3. Deploy Helm Chart

helm upgrade --install api charts/api/ -f charts/api/values.yaml

Security & Networking

Ingress TLS is managed via Cloudflare and GCP.

Cloud Armor is used for DDoS protection.

RBAC is configured for Kubernetes security.

Monitoring & Logging

Metrics Collection: Uses Grafana/Agent and kube-state-metrics.

Log Aggregation: Integrated with GCP Logging.

Alerting: Configured in Grafana Cloud.

Contact

For any issues or contributions, please submit a pull request or open an issue in this repository.

