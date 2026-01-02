#!/usr/bin/env bash

# Copyright 2024
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# "---------------------------------------------------------"
# "-                                                       -"
# "-  Configure HPA with external metrics support          -"
# "-                                                       -"
# "---------------------------------------------------------"

set -o errexit
set -o nounset
set -o pipefail

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
# shellcheck source=scripts/common.sh
source "$ROOT"/scripts/common.sh

echo "Installing Stackdriver Custom Metrics Adapter..."

# Install the custom metrics adapter for external metrics
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/k8s-stackdriver/master/custom-metrics-stackdriver-adapter/deploy/production/adapter_new_resource_model.yaml

echo "Waiting for adapter namespace to be created..."
kubectl wait --for=jsonpath='{.status.phase}'=Active --timeout=60s namespace/custom-metrics || true

# Get the Stackdriver adapter service account email from Terraform output
ADAPTER_SA_EMAIL=$(cd "$ROOT/terraform"; terraform output -raw stackdriver_adapter_service_account_email)

echo "Annotating Stackdriver adapter service account with Workload Identity..."
kubectl annotate serviceaccount custom-metrics-stackdriver-adapter \
  -n custom-metrics \
  iam.gke.io/gcp-service-account="${ADAPTER_SA_EMAIL}" \
  --overwrite

echo "Restarting adapter to apply Workload Identity..."
kubectl rollout restart deployment custom-metrics-stackdriver-adapter -n custom-metrics

echo "Waiting for adapter deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/custom-metrics-stackdriver-adapter -n custom-metrics || true

echo "Stackdriver adapter installed successfully!"

# Substitute PROJECT_ID in the Kubernetes manifest
echo "Updating PROJECT_ID in hello-server.yaml..."
sed -i "s/PROJECT_ID/${PROJECT}/g" "$ROOT/k8s/hello-server.yaml"

echo "HPA configuration completed!"
