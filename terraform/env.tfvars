# Terraform env variables

gcp_project                   = "abiding-envoy-449913-f1"
cluster                       = "api"
region                        = "us-central1"
zone                          = "us-central1-c"
vpc_network                   = "api-vpc"
vpc_subnet                    = "api-subnet"
vpc_subnet_range              = "172.27.0.0/16"
pod_address_range_name        = "pod-address-range"
pod_ip_cidr_range             = "172.28.0.0/14"
service_address_range_name    = "service-address-range"
service_ip_cidr_range         = "172.26.0.0/17"
master_ipv4_cidr_block        = "172.26.128.0/28"
cluster_secondary_range_name  = "pod-address-range"
services_secondary_range_name = "service-address-range"
router_name                   = "api-router"
nat_name                      = "api-nat"
apis = [
  "iap.googleapis.com",
  "secretmanager.googleapis.com",
  "container.googleapis.com",
  "storage.googleapis.com",
  "artifactregistry.googleapis.com"]