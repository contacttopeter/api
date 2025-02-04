# api

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

- Create GCP bucket
gcloud storage buckets create gs://api-bucket-default --location=us-central1

- Enable Cloud Resource Manager API
gcloud services enable cloudresourcemanager.googleapis.com

- Generate PAT 
In your GitHub acount and create RUNNER_REGISTRATION_TOKEN ecret in web interface