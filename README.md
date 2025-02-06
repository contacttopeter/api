## Goal
Purpose of this repository is demonstrates the ability to automate the deployment of a dockerized application using a **GitHub CI pipeline**.
Data from [provider](https://api.coinbase.com/v2/exchange-rates) are taken and exposed [here](https://api.prochazka.cc) for CZK every hour.

### API Deployment Infrastructure

This repository manages the infrastructure and deployment, which is is automated using Terraform, Helm, Docker, and GitHub Actions.

## Infrastructure and Tools
- **Cloud compute**
- **Cloud storage**
- **Docker**
- **Terraform**
- **Bash**

## Task
1. Download regularly (e.g., daily/hourly) a dataset from a free data provider: [https://api.coinbase.com/v2/exchange-rates](https://api.coinbase.com/v2/exchange-rates).
2. Store the downloaded dataset to cloud storage.
3. Extract specific data from each dataset: **Current Exchange Rates (CZK)**.
4. Display all extracted data using a simple HTML page served from cloud storage.
5. Present the result in this **README file**.

## Instructions
- Use a well-known programming language to implement the application/script logic.
- Encapsulate the code and its dependencies inside a **Docker container**.
- Use **Terraform** to automate provisioning of cloud resources.
- Use **GitHub** to:
  - Store all source code, including this README.md to explain the approach and present the working result.
  - Use **GitHub Actions** to enforce coding practices and automate deployment to the cloud environment.
  - Document any encountered problems, todos, and future considerations.

## Repository Structure
```
/api-main
├── .github/workflows/      # CI/CD Pipelines (Terraform, Helm, Docker)
├── charts/api/             # Helm Chart for Kubernetes deployment
├── terraform/              # Terraform configurations for GCP infrastructure
├── Dockerfile              # Docker build configuration
├── README.md               # Project documentation
└── other config files...
```

## Infrastructure Details
### 1. Google Cloud Platform (GCP)
- Core infrastructure is managed using **Terraform**.
- Components include:
  - **GKE (Google Kubernetes Engine)** for running workloads.
  - **VM bastion** for deply Kubernetes resources
  - **Cloud Storage** for storing provider data.
  - **Cloud Artifact Registry** for store docker image

### 2. Kubernetes Deployments
- Managed using **Helm**.
- Helm chart located under `charts/api/`.
- Manages all Kubernetes resources

### 3. CI/CD Pipeline
The deployment pipeline is automated via **GitHub Actions** and is structured into:
- **Docker Build & Push:** Builds the custom nginx container and pushes it to the registry.
- **Helm Deployment:** Updates Kubernetes using the Helm chart.
- **Terraform Apply:** Updates GCP infrastructure as needed.

## Deployment Workflow
**Terraform Plan & Apply**:
- GitHub Action is triggered by PR to main branch and do Terraform Plan
- After merge to main branch do Terraform Apply
- State file is in GCP storage
- There is possibility to run Terraform action by manual trigger

## Docker Image Build & Push
- GitHub Action is triggered by PR to main branch and do buid docker image
- After merge to main branch do build and push to Docker registry
- Including this process is versioning of image

### Helm Chart Deployment
- GitHub Action is triggered by PR to main branch and do build helm package
- After merge to main branch do build and push to Storage
- Including this process is versioning of helm package


### 4. Security & Networking
- **Ingress TLS** is managed via GCP.
- **RBAC** is configured for Kubernetes security.

### 5. Monitoring & Logging
- TBD

### 6. Manual Steps
- There is still couple manual steps which needs to be done when you will get clean GCP projects. Some of them can be covered by Init Github Actions which will be run just once on the initialization phase.

1. **Create GCP Service Account for Terraform:**
    ```sh
    gcloud iam service-accounts create terraform \
        --description="Terraform Service Account" \
        --display-name="Terraform"
    ```

2. **Grant Owner Role:**
    ```sh
    gcloud projects add-iam-policy-binding $(gcloud config get-value project) \
        --member="serviceAccount:terraform@$(gcloud config get-value project).iam.gserviceaccount.com" \
        --role="roles/owner"
    ```

3. **Generate a Key for the Service Account:**
    ```sh
    gcloud iam service-accounts keys create terraform-key.json \
        --iam-account=terraform@$(gcloud config get-value project).iam.gserviceaccount.com
    ```

4. **Create `API_GOOGLE_CREDENTIALS` GitHub Secret:**
    ```sh
    cat terraform-key.json
    ```

5. **Add to Docker Credentials:**
    - Go to Secret Manager and create `docker-credentials` secret with the content of `terraform-key.json`.

6. **Create GCP Bucket:**
    ```sh
    gcloud storage buckets create gs://api-bucket-default --location=us-central1
    ```

7. **Enable Uniform Bucket Level Access (UBLA) on your GCS Bucket:**
    ```sh
    gcloud storage buckets update gs://api-bucket-default --uniform-bucket-level-access
    ```

8. **Enable Cloud Resource Manager API:**
    ```sh
    gcloud services enable cloudresourcemanager.googleapis.com
    ```

9. **Generate PAT:**
    - In your GitHub account, create `RUNNER_REGISTRATION_TOKEN` secret in the web interface.
