/*
Copyright 2024

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

///////////////////////////////////////////////////////////////////////////////////////
//
// This configuration will create a GKE cluster 
//
///////////////////////////////////////////////////////////////////////////////////////

// Provides access to available Google Container Engine versions in a zone for a given project.
// https://www.terraform.io/docs/providers/google/d/google_container_engine_versions.html
data "google_container_engine_versions" "on-prem" {
  location = var.zone
  project  = var.project
}

///////////////////////////////////////////////////////////////////////////////////////
// Create the resources needed for GKE
///////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////
// Create the primary cluster for this project.
///////////////////////////////////////////////////////////////////////////////////////

// Create the GKE Cluster
// https://www.terraform.io/docs/providers/google/d/google_container_cluster.html
resource "google_container_cluster" "primary" {
  name               = "gke-public-cluster-example"
  location           = var.zone
  initial_node_count = 2
  min_master_version = data.google_container_engine_versions.on-prem.latest_master_version

  // Enable Workload Identity
  workload_identity_config {
    workload_pool = "${var.project}.svc.id.goog"
  }

  // Enable monitoring for external metrics
  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  // Enable required addons
  addons_config {
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
    
    // Enable Workload Identity on nodes
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  // These local-execs are used to provision the sample service using Kubernetes manifests
  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --zone ${google_container_cluster.primary.location} --project ${var.project}"
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ../k8s/hello-server.yaml"
  }
}

///////////////////////////////////////////////////////////////////////////////////////
// Create Pub/Sub resources
///////////////////////////////////////////////////////////////////////////////////////

// Create a Pub/Sub topic
// https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic
resource "google_pubsub_topic" "gke_notifications" {
  name    = "gke-notifications-topic"
  project = var.project

  labels = {
    environment = "example"
    managed_by  = "terraform"
  }
}

// Create a Pub/Sub subscription
// https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_subscription
resource "google_pubsub_subscription" "gke_notifications_sub" {
  name    = "gke-notifications-subscription"
  topic   = google_pubsub_topic.gke_notifications.name
  project = var.project

  labels = {
    environment = "example"
    managed_by  = "terraform"
  }

  // Acknowledge deadline in seconds (10-600)
  ack_deadline_seconds = 20

  // Retain acknowledged messages for 7 days
  retain_acked_messages = true
  message_retention_duration = "604800s" // 7 days

  // Expiration policy - subscription expires if inactive for 31 days
  expiration_policy {
    ttl = "2678400s" // 31 days
  }
}

///////////////////////////////////////////////////////////////////////////////////////
// Create service account for HPA to access Cloud Monitoring metrics
///////////////////////////////////////////////////////////////////////////////////////

resource "google_service_account" "hpa_sa" {
  account_id   = "gke-hpa-metrics"
  display_name = "GKE HPA Metrics Reader"
  project      = var.project
}

// Grant monitoring viewer role to read Pub/Sub metrics
resource "google_project_iam_member" "hpa_monitoring_viewer" {
  project = var.project
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.hpa_sa.email}"
}

// Allow Kubernetes service account to impersonate GCP service account
resource "google_service_account_iam_member" "workload_identity_binding" {
  service_account_id = google_service_account.hpa_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project}.svc.id.goog[default/hello-server]"
}

// Output the Pub/Sub topic and subscription names
output "pubsub_topic_name" {
  description = "The name of the Pub/Sub topic"
  value       = google_pubsub_topic.gke_notifications.name
}

output "pubsub_subscription_name" {
  description = "The name of the Pub/Sub subscription"
  value       = google_pubsub_subscription.gke_notifications_sub.name
}

output "hpa_service_account_email" {
  description = "The email of the service account for HPA metrics"
  value       = google_service_account.hpa_sa.email
}

