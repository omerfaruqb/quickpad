# Terraform configuration for Quickpad GCP infrastructure
# This provides Infrastructure as Code (IaC) for bonus points

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# MongoDB VM Instance
resource "google_compute_instance" "mongodb" {
  name         = "mongodb-vm"
  machine_type = "e2-small"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
      type  = "pd-ssd"
    }
  }

  network_interface {
    network = "default"
    access_config {
      # Ephemeral public IP (not needed but helps with setup)
    }
  }

  tags = ["mongodb"]

  metadata_startup_script = file("${path.module}/../vm-scripts/setup-mongodb.sh")

  service_account {
    email  = google_service_account.mongodb.email
    scopes = ["cloud-platform"]
  }
}

# Firewall rule for MongoDB (internal only)
resource "google_compute_firewall" "mongodb_internal" {
  name    = "allow-mongodb-internal"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["27017"]
  }

  source_ranges = ["10.0.0.0/8"]
  target_tags   = ["mongodb"]
}

# GKE Cluster
resource "google_container_cluster" "quickpad_cluster" {
  name     = "quickpad-cluster"
  location = var.region

  # Use Autopilot for easier management (or remove for standard cluster)
  enable_autopilot = var.enable_autopilot

  # If not using Autopilot, configure node pool
  dynamic "node_pool" {
    for_each = var.enable_autopilot ? [] : [1]
    content {
      name       = "default-pool"
      node_count = 2

      node_config {
        machine_type = "e2-small"
        disk_size_gb = 20

        oauth_scopes = [
          "https://www.googleapis.com/auth/cloud-platform"
        ]
      }
    }
  }

  network    = "default"
  subnetwork = "default"

  # Enable workload identity for better security
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}

# Service Account for MongoDB VM
resource "google_service_account" "mongodb" {
  account_id   = "mongodb-vm"
  display_name = "MongoDB VM Service Account"
}

# Cloud Function: Cleanup Notes
resource "google_cloudfunctions_function" "cleanup_notes" {
  name        = "cleanup-expired-notes"
  description = "Cleanup expired notes from MongoDB"
  runtime     = "nodejs20"
  region      = var.region

  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.functions.name
  source_archive_object = google_storage_bucket_object.cleanup_notes.name
  trigger {
    http_trigger {}
  }

  entry_point = "cleanupExpiredNotes"
  environment_variables = {
    MONGODB_URL = "mongodb://quickpad:${var.mongodb_password}@${google_compute_instance.mongodb.network_interface[0].network_ip}:27017/quickpad"
  }
}

# Cloud Scheduler for cleanup job
resource "google_cloud_scheduler_job" "cleanup_notes" {
  name     = "cleanup-expired-notes-job"
  schedule = "0 * * * *" # Every hour
  region   = var.region

  http_target {
    http_method = "POST"
    uri         = google_cloudfunctions_function.cleanup_notes.https_trigger_url

    oidc_token {
      service_account_email = google_service_account.cloud_functions.email
    }
  }
}

# Cloud Function: Analytics
resource "google_cloudfunctions_function" "analytics" {
  name        = "process-analytics"
  description = "Process analytics data"
  runtime     = "nodejs20"
  region      = var.region

  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.functions.name
  source_archive_object = google_storage_bucket_object.analytics.name
  trigger {
    http_trigger {}
  }

  entry_point = "processAnalytics"
  environment_variables = {
    MONGODB_URL = "mongodb://quickpad:${var.mongodb_password}@${google_compute_instance.mongodb.network_interface[0].network_ip}:27017/quickpad"
  }
}

# Storage bucket for Cloud Functions
resource "google_storage_bucket" "functions" {
  name     = "${var.project_id}-cloud-functions"
  location = var.region
}

# Service Account for Cloud Functions
resource "google_service_account" "cloud_functions" {
  account_id   = "cloud-functions"
  display_name = "Cloud Functions Service Account"
}

# Note: Cloud Function source archives need to be created manually or via CI/CD
# This is a placeholder - you'll need to zip and upload the functions
resource "google_storage_bucket_object" "cleanup_notes" {
  name   = "cleanup-notes.zip"
  bucket = google_storage_bucket.functions.name
  source = "${path.module}/../cloud-functions/cleanup-notes.zip"
}

resource "google_storage_bucket_object" "analytics" {
  name   = "analytics.zip"
  bucket = google_storage_bucket.functions.name
  source = "${path.module}/../cloud-functions/analytics.zip"
}

# Outputs
output "mongodb_internal_ip" {
  value       = google_compute_instance.mongodb.network_interface[0].network_ip
  description = "Internal IP address of MongoDB VM"
}

output "gke_cluster_name" {
  value       = google_container_cluster.quickpad_cluster.name
  description = "Name of the GKE cluster"
}

output "gke_cluster_endpoint" {
  value       = google_container_cluster.quickpad_cluster.endpoint
  description = "Endpoint of the GKE cluster"
}

output "cleanup_function_url" {
  value       = google_cloudfunctions_function.cleanup_notes.https_trigger_url
  description = "URL of the cleanup notes Cloud Function"
}

