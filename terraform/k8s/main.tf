provider "google" {
  project = var.gcp_project
  zone    = var.zone
}

data "terraform_remote_state" "gcp" {
  backend = "gcs"
  config = {
    bucket = "api-bucket-default"
    prefix = "gcp"
  }
}

data "google_client_config" "api-cluster" {
}

data "google_container_cluster" "api-cluster" {
  name     = var.cluster
  location = var.zone
}

provider "kubernetes" {
  host  = "https://${data.google_container_cluster.api-cluster.endpoint}"
  token = data.google_client_config.api-cluster.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.api-cluster.master_auth[0].cluster_ca_certificate,
  )
}
provider "helm" {
  kubernetes {
    host  = "https://${data.google_container_cluster.api-cluster.endpoint}"
    token = data.google_client_config.api-cluster.access_token
    cluster_ca_certificate = base64decode(
    data.google_container_cluster.api-cluster.master_auth[0].cluster_ca_certificate, )
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "gke-gcloud-auth-plugin"
    }
  }
}

resource "kubernetes_namespace" "api-namespace" {
  metadata {
    name = "${var.cluster}-env"
    labels = {
      "name" = "${var.cluster}-env"
    }
  }
}

resource "kubernetes_service_account" "ksa" {
  metadata {
    name      = "ksa"
    namespace = "${var.cluster}-env"
  }
}

data "google_secret_manager_secret_version" "docker-credentials" {
  secret = "docker-credentials"
}

resource "kubernetes_secret" "api-docker-credentials" {
  metadata {
    name      = "docker-credentials"
    namespace = "${var.cluster}-env"
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "https://gcr.io" = {
          "username" = "_json_key"
          "password" = data.google_secret_manager_secret_version.docker-credentials.secret_data
          "email"    = "api-terraform@abiding-envoy-449913-f1.iam.gserviceaccount.com"
        }
      }
    })
  }
}

resource "kubernetes_manifest" "managedcertificate_managed_cert" {
  manifest = {
    apiVersion = "networking.gke.io/v1"
    kind       = "ManagedCertificate"
    metadata = {
      namespace = "${var.cluster}-env"
      name      = "${var.cluster}-cert"
    }
    spec = {
      domains = ["api.prochazka.cc"]
    }
  }
}

resource "helm_release" "api_helm" {
  name       = "api"
  repository = "gs://api-bucket-default/helm"
  chart      = "api"
  version    = var.chart_version
  namespace  = "${var.cluster}-env"
  values = [
    "${file("../../versions/api-web.yaml")}"
  ]
  atomic = true
  lint   = true
}