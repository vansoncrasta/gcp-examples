# GKE Public Cluster with Pub/Sub example
Example to deploy GKE public cluster with Google Cloud Pub/Sub topic and subscription

This example demonstrates:
- Creating a GKE public cluster with 2 nodes
- Deploying a sample hello-server application using Kubernetes YAML manifests
- Creating a Pub/Sub topic for notifications
- Creating a Pub/Sub subscription to consume messages

## Prerequisites
- gcloud CLI configured with project, region, and zone
- kubectl installed
- Terraform >= 0.12

## Setup
```
gcloud config set project PROJECT_ID

gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-c

```

```
mkdir deploy
cd deploy
git init
git remote add -f origin https://github.com/vansoncrasta/gcp-examples
git config core.sparseCheckout true
git sparse-checkout set gke-public-cluster-pub-sub
git pull origin main
chmod -R 777 gke-public-cluster-pub-sub
cd gke-public-cluster-pub-sub
```

## Deploy

```
make create
make validate
make teardown
```

## Project Structure

- `k8s/hello-server.yaml` - Kubernetes manifest for the hello-server deployment and service
- `terraform/` - Terraform configuration for GKE cluster and Pub/Sub resources
- `scripts/` - Helper scripts for deployment, validation, and teardown
- `test/` - Linting and boilerplate validation scripts
