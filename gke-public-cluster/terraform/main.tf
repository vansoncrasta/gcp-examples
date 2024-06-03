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

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  // These local-execs are used to provision the sample service
  // These local-execs are used to provision the sample service
  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --zone ${google_container_cluster.primary.location} --project ${var.project}"
  }

  provisioner "local-exec" {
    command = "kubectl --namespace default create deployment hello-server --image gcr.io/google-samples/hello-app:1.0"
  }

  provisioner "local-exec" {
    command = "kubectl --namespace default expose deployment hello-server --type \"LoadBalancer\" --port=8080"
  }
}

