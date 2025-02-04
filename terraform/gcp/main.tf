provider "google" {
  project = var.gcp_project
  zone    = var.zone
}

resource "google_project_service" "api" {
  for_each = toset(var.apis)
  service  = each.key
  project  = var.gcp_project

  disable_on_destroy         = true
  disable_dependent_services = true
}

resource "google_compute_global_address" "hec-gw" {
  name         = "${var.cluster}-public-address"
  project      = var.gcp_project
  description  = "External IP for the API"
  address_type = "EXTERNAL"
}

resource "google_compute_network" "vpc-network" {
  project                         = var.gcp_project
  name                            = var.vpc_network
  auto_create_subnetworks         = false
  mtu                             = 1460
  delete_default_routes_on_create = false
}

resource "google_compute_subnetwork" "vpc-subnet" {
  name                     = var.vpc_subnet
  ip_cidr_range            = var.vpc_subnet_range
  region                   = var.region
  network                  = google_compute_network.vpc-network.id
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = var.pod_address_range_name
    ip_cidr_range = var.pod_ip_cidr_range
  }
  secondary_ip_range {
    range_name    = var.service_address_range_name
    ip_cidr_range = var.service_ip_cidr_range
  }
}

resource "google_compute_router" "hec-router" {
  name       = var.router_name
  network    = google_compute_network.vpc-network.id
  region     = google_compute_subnetwork.vpc-subnet.region
  depends_on = [google_compute_subnetwork.vpc-subnet]
}

data "google_project" "gcp_project" {
  project_id = var.gcp_project
}

output "project_number" {
  value = data.google_project.gcp_project.number
}


resource "google_compute_router_nat" "hec-nat" {
  name                                = var.nat_name
  nat_ip_allocate_option              = "AUTO_ONLY"
  router                              = google_compute_router.hec-router.name
  region                              = google_compute_subnetwork.vpc-subnet.region
  min_ports_per_vm                    = 4096
  source_subnetwork_ip_ranges_to_nat  = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  enable_endpoint_independent_mapping = false
  enable_dynamic_port_allocation      = true
  log_config {
    enable = true
    filter = "ALL"
  }
  depends_on = [google_compute_router.hec-router]
}

resource "google_service_account" "cluster-sa" {
  account_id   = "cluster-sa"
  display_name = "Cluster Service Account"
  project      = var.gcp_project
}

resource "google_service_account" "k8s-sa" {
  account_id   = "k8s-sa"
  display_name = "K8s Service Account"
  project      = var.gcp_project
}

resource "google_container_cluster" "primary" {
  name                     = var.cluster
  location                 = var.zone
  remove_default_node_pool = true
  deletion_protection      = false
  initial_node_count       = 1
  networking_mode          = "VPC_NATIVE"
  network                  = var.vpc_network
  subnetwork               = var.vpc_subnet

  workload_identity_config {
    workload_pool = "${var.gcp_project}.svc.id.goog"
  }

  master_authorized_networks_config {
  }

  private_cluster_config {
    enable_private_endpoint = true
    enable_private_nodes    = true
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = var.cluster_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  addons_config {

    gcs_fuse_csi_driver_config {
      enabled = true
    }
  }

  depends_on = [google_compute_subnetwork.vpc-subnet]
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster}-pool"
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    metadata = {
      disable-legacy-endpoints = true
    }
    preemptible     = true
    machine_type    = "n2d-standard-2"
    service_account = google_service_account.cluster-sa.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
  autoscaling {
    min_node_count = 1
    max_node_count = 1
  }
}

resource "google_service_account_iam_binding" "ksa_to_gsa_binding" {
  depends_on         = [google_service_account.k8s-sa]
  service_account_id = "projects/${var.gcp_project}/serviceAccounts/k8s-sa@${var.gcp_project}.iam.gserviceaccount.com"
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${var.gcp_project}.svc.id.goog[${var.cluster}-env/ksa]"
  ]
  depends_on = [google_container_node_pool.primary_nodes]
}

resource "google_project_iam_binding" "storage_object_user" {
  project = ${var.gcp_project}
  role    = "roles/storage.objectUser"

  members = [
    "principal://iam.googleapis.com/projects/${data.google_project.gcp_project.number}/locations/global/workloadIdentityPools/${var.gcp_project}.svc.id.goog/subject/ns/api-env/sa/ksa"
  ]
}


module "bastion-host-gcp" {
  source                = "terraform-google-modules/bastion-host/google"
  version               = "8.0.0"
  project               = var.gcp_project
  zone                  = var.zone
  name                  = "${var.cluster}-bastion"
  network               = google_compute_network.vpc-network.id
  subnet                = google_compute_subnetwork.vpc-subnet.id
  machine_type          = "e2-medium"
  disk_size_gb          = 10
  image_project         = "ubuntu-os-cloud"
  image_family          = "ubuntu-2204-lts"
  service_account_roles = ["roles/logging.logWriter", "roles/monitoring.metricWriter", "roles/monitoring.viewer", "roles/compute.osLogin", "roles/container.admin", "roles/storage.objectAdmin"]
  additional_ports      = [3389]
  startup_script = templatefile("../../scripts/startup-script.sh", {
    gcp_project         = var.gcp_project
    zone                = var.zone
    cluster             = var.cluster
    github_runner_token = var.github_runner_token
  })
  depends_on = [google_compute_subnetwork.vpc-subnet]
}