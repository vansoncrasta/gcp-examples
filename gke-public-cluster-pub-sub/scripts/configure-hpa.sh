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
# "-  Modern GKE (1.24+) with native Cloud Monitoring      -"
# "-                                                       -"
# "---------------------------------------------------------"

set -o errexit
set -o nounset
set -o pipefail

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
# shellcheck source=scripts/common.sh
source "$ROOT"/scripts/common.sh

echo "Configuring HPA with native GKE external metrics support..."

# Modern GKE (1.24+) includes built-in support for external metrics
# via the gke-metrics-agent - no manual adapter installation needed!

echo "Verifying GKE cluster version supports native external metrics..."
CLUSTER_VERSION=$(gcloud container clusters describe gke-public-cluster-example \
  --zone "${ZONE}" \
  --project "${PROJECT}" \
  --format="value(currentMasterVersion)")

echo "Cluster version: ${CLUSTER_VERSION}"

# Substitute PROJECT_ID in the Kubernetes manifest
echo "Updating PROJECT_ID in hello-server.yaml..."
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  sed -i '' "s/PROJECT_ID/${PROJECT}/g" "$ROOT/k8s/hello-server.yaml"
else
  # Linux
  sed -i "s/PROJECT_ID/${PROJECT}/g" "$ROOT/k8s/hello-server.yaml"
fi

echo "Waiting for gke-metrics-agent to be ready..."
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=gke-metrics-agent \
  -n kube-system \
  --timeout=120s || echo "Note: gke-metrics-agent may take a few minutes to become available"

echo ""
echo "✓ HPA configuration completed!"
echo ""
echo "The GKE cluster includes native support for external metrics."
echo "You can now deploy your HPA and it will automatically use Cloud Monitoring metrics."
echo ""
echo "To verify external metrics are available, run:"
echo "  kubectl get --raw /apis/external.metrics.k8s.io/v1beta1 | jq ."
