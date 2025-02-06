## Goal
Purpose of this repository demonstrates the ability to automate the deployment of a dockerized application using a **GitHub CI/CD pipeline**.
Data from [provider](https://api.coinbase.com/v2/exchange-rates) are taken and exposed [here](https://api.prochazka.cc) for CZK every hour.

### Decision how to do it
Biggest concern was which approach to choose. There were two options:
1. Simplest solution (use serverless model) Cloud Run service and job
2. Use complex solution which is GKE cluster and Kubernetes resources
#### I have chosen second option to be able show more complex solution which will be similar to real situation.

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
├── www/                    # Frontend code
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

#### Deployment Workflow
**Terraform Plan & Apply**:
- GitHub Action is triggered by PR to main branch and do Terraform Plan.
- After merge to main branch do Terraform Apply.
- State files are in GCP storage.
- There is possibility to run Terraform action by manual trigger.

#### Docker Image Build & Push
- GitHub Action is triggered by PR to main branch and do build docker image.
- After merge to main branch do build and push to Docker registry.
- New version of docker image is stored in /versions/api-web.yaml

#### Helm Chart Deployment
- GitHub Action is triggered by PR to main branch and do build helm package
- After merge to main branch do build and push to Storage
- New version of helm chart is stored in /versions/helm-chart.yaml


### 4. Security & Networking
- **Ingress TLS** is managed via GCP.
- **RBAC** is configured for Kubernetes security.

### 6. Manual Steps
- There are still couple manual steps which needs to be done when you will get clean GCP projects. Some of them can be covered by Init GitHub Actions which will be run just once on the initialization phase.

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
This needs to be taken just like skeleton how it can work but there are log of things which needs to be done.

## Infrastructure Enhancements
1. **Multi-Region Deployment for High Availability**
   - Deploy workloads in multiple GKE clusters across different regions.
   - Use **Google Cloud Load Balancer** to route traffic dynamically.
2. **Workload Identity for Kubernetes Service Accounts**
   - Reduce the need for GCP IAM keys by using Workload Identity
3. **Service Mesh with Istio or Linkerd**
   - Implement **Istio** for better traffic routing, observability, and security.
   - Enable **mTLS** for secure inter-service communication.
4. **Kubernetes Autoscaling Optimization**
   - Implement **Horizontal Pod Autoscaler (HPA)** based on CPU, memory, or custom application metrics.
   - Use **Cluster Autoscaler** to scale GKE nodes dynamically.
5. **Database & Caching Layer**
   - Consider **Cloud SQL** (managed PostgreSQL/MySQL) for structured data.
   - Use **Redis or Memcached** as a caching layer to reduce API response times.
6. **Monitoring & Logging Improvements**
   - Implement **OpenTelemetry** for better distributed tracing.
   - Use **Grafana Loki** for logging to replace Stackdriver/Cloud Logging.
   - Set up **Alerting in Prometheus** for abnormal behavior detection.
7. **Use Terraform Cloud or Atlantis for Automated Terraform Execution**
   - Terraform state management and execution can be automated using **Terraform Cloud**.
8. **Artifact Registry Instead of Container Registry**
   - Since **Container Registry is deprecated**, migrate to **Artifact Registry** for storing container images.

## CI/CD Pipeline Enhancements
1. **ArgoCD or Flux for GitOps Deployment**
   - Replace Helm deployments in GitHub Actions with **ArgoCD** or **FluxCD** for declarative, automated deployments.
2. **Feature Branch Deployments with Preview Environments**
   - Deploy separate environments per feature branch using **VCluster** or ephemeral GKE namespaces.
3. **Use a Dedicated Build System for Docker**
   - Utilize **Google Cloud Build** for faster, managed builds instead of running them inside GitHub Actions.
4. **Automated Rollbacks with Health Checks**
   - Use cabary or blue/green strategy with automated rollbacks based on failure conditions.
5. **Dependency Management Automation**
   - Implement **Dependabot** or **Renovate** to keep Docker, Helm, and Terraform dependencies updated.

## Security Enhancements
1. **Cloud Armor & WAF Rules**
   - Use **Google Cloud Armor** to block malicious traffic.
   - Enable **Rate Limiting** to prevent API abuse.
2. **Cloudflare Proxy for Enhanced DDoS Protection**
   - Route traffic through **Cloudflare** to reduce attack surface.
3. **Least Privilege IAM Policies**
   - Regularly audit IAM roles to enforce **least privilege**.
4. **TLS Security Hardening**
   - Enforce **TLS 1.2+ only**, disable weak ciphers.
5. **Docker Image Security Scanning**
   - Enable **GCP's Container Analysis** to scan Docker images before deployment.

## Code Quality Enhancements
1. **Static Code Analysis**
   - Use **SonarQube, ESLint, or Bandit** to analyze Terraform, Bash, and Python code.
2. **Unit & Integration Testing Before Deployment**
   - Write **unit tests for data extraction logic** and run them before building a Docker image.
3. **Mutation Testing for More Robust Code**
   - Use **mutation testing frameworks** to detect missing test cases.