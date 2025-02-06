## Goal
Purpose of this repository is demonstrates the ability to automate the deployment of a dockerized application using a **GitHub CI/CD pipeline**.
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
  - **VM bastion** for deploy Kubernetes resources and be GKE bastion.
  - **Cloud Storage** for storing provider data.
  - **Cloud Container Registry** for store docker image

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
- GitHub Action is triggered by PR to main branch and do Terraform Plan.
- After merge to main branch do Terraform Apply.
- State files are in GCP storage.
- There is possibility to run Terraform action by manual trigger.

## Docker Image Build & Push
- GitHub Action is triggered by PR to main branch and do buid docker image.
- After merge to main branch do build and push to Docker registry.
- New version of docker image is stored in /versions/api-web.yaml

### Helm Chart Deployment
- GitHub Action is triggered by PR to main branch and do build helm package
- After merge to main branch do build and push to Storage
- New version of helm chart is stored in /versions/helm-chart.yaml


### 4. Security & Networking
- **Ingress TLS** is managed via GCP.
- **RBAC** is configured for Kubernetes security.

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

## What needs to be done?
This needs to be taken just like sceleton how it can works but there are log of things which needs to be done.

## Infrastructure
- For now everything is on one GKE node, we should start use autoscaling incling nodes and pods.
- Good aproach can be using some servis mesh like Istio and use custom metric (like request total) for autoscaling or the pods.
- If our application will get more complicated we should consider to use Gateway API instead of Ingress which brings more setting.
- In cron job we use third party image like badouralix/curl-jq we need to create some our own image.
- We should consider to use containerized self hosted Github runners to save cost (VM GitHub runner can be turned off and be used just on demand like bastion server) good approcah is use Actions Runner Controller https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller
- Container registry will be depricated, we shoud use Artifact registry instad of it.
- We use one Google storage gs://api-bucket-default for everything it should be devided by purppose (Terrafrom, Helm package, Data,...).

## CI/CD Pipeline + code quality
- We need to also thing about branching strategy (for example, Trunk based, Release branch, Environment branch,...). How offen we want to deploy? How good we are in testing? We need to consider and use strategy according our needs.
- Consider to devide repositories to more than one to have easier contorol. It could be for Code + Docker build, Helm + chart package build, Configuration, Terraform.
- If we will have more than one environment we can start to use [helmfile](https://github.com/helmfile/helmfile) for better env versioning.
- Instead of Github Actions which deploy helm we can consider some orchestration tool like ArgoCD or Flux.
- We should start to use testing our code before creating image by some Whitesource, Gitleaks, Sonarqube, ...
- If we want to test after deployment, we should consider if we are able to do testing in Canary or Blue Green deployment strategy.

## Security
- We should use some reverse proxy like CloudFlare which will increase our security.
- Using CloudArmor we can get protection against attacks like DDos, XXS, SQLi.
- Setting of SSL policy we can denied old TLS version and weak ciphers.
- In firewall we need enable just ports what we need.
- IAM grant lowest privilages to users and service accounts as possible.
- Do scan docker images against vulnerability