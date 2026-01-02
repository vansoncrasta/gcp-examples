#!/bin/bash -e

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
# "-  Validation script checks if Cassandra                -"
# "-  deployed successfully.                               -"
# "-                                                       -"
# "---------------------------------------------------------"

# bash "strict-mode", fail immediately if there is a problem
set -euo pipefail

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
# shellcheck source=scripts/common.sh
source "$ROOT"/scripts/common.sh

# Get the kubectl credentials for the GKE cluster.
gcloud container clusters get-credentials "$CLUSTER_NAME" --zone "$ZONE" --project "$PROJECT"

APP_NAME=hello-server
APP_MESSAGE="deployment \"$APP_NAME\" successfully rolled out"
RETRY_COUNT=30

# Loop for up to 60 seconds waiting for the rollout of hello-server to finish
SUCCESSFUL_ROLLOUT=false
for ((i=0; i < RETRY_COUNT ; i++)); do
  ROLLOUT=$(kubectl rollout status -n default \
    --watch=false deployment/"$APP_NAME") &> /dev/null
  if [[ $ROLLOUT = *"$APP_MESSAGE"* ]]; then
    SUCCESSFUL_ROLLOUT=true
    break
  fi
  sleep 2
done

if [ "$SUCCESSFUL_ROLLOUT" = false ]
then
  echo "ERROR - Application failed to deploy"
  exit 1
fi
echo "Step 1 of the validation passed. App is deployed."

# Loop for up to 60 seconds waiting for service's IP address
EXT_IP=""
for ((i=0; i < RETRY_COUNT ; i++)); do
  EXT_IP=$(kubectl get svc "$APP_NAME" -n default \
    -ojsonpath='{.status.loadBalancer.ingress[0].ip}')
  [ -n "$EXT_IP" ] && break
  sleep 2
done
if [ -z "$EXT_IP" ]
then
  echo "ERROR - Timed out waiting for IP"
  exit 1
fi

# Get service's port
EXT_PORT=$(kubectl get service "$APP_NAME" -n default \
  -o=jsonpath='{.spec.ports[0].port}')

echo "App is available at: http://$EXT_IP:$EXT_PORT"

# Test service availability
SERVICE_AVAILABLE=false
# Loop in the test to allow the service time to become available.  They Loop
# will continue until either the retry count is met, or a return code of 200
# is received.
for ((i=0; i < RETRY_COUNT; i++)); do
  RETURN_CODE=$(curl -s -o /dev/null -w '%{http_code}' "$EXT_IP:$EXT_PORT"/)
  if [[ $RETURN_CODE = 200 ]]; then
    echo "Step 2 of the validation passed. App handles requests."
    SERVICE_AVAILABLE=true
    break
  fi
  sleep 20
done
# If the service was not found send message and exit
if [ "$SERVICE_AVAILABLE" = false ]
then
  echo "Unable to access the app!"
  exit 1
fi

# Validate Pub/Sub resources
echo "Step 3: Validating Pub/Sub resources..."

# Check if the Pub/Sub topic exists
TOPIC_NAME="gke-notifications-topic"
TOPIC_EXISTS=$(gcloud pubsub topics list --filter="name:$TOPIC_NAME" --project="$PROJECT" --format="value(name)")

if [ -z "$TOPIC_EXISTS" ]
then
  echo "ERROR - Pub/Sub topic '$TOPIC_NAME' not found"
  exit 1
fi
echo "Pub/Sub topic '$TOPIC_NAME' exists."

# Check if the Pub/Sub subscription exists
SUBSCRIPTION_NAME="gke-notifications-subscription"
SUBSCRIPTION_EXISTS=$(gcloud pubsub subscriptions list --filter="name:$SUBSCRIPTION_NAME" --project="$PROJECT" --format="value(name)")

if [ -z "$SUBSCRIPTION_EXISTS" ]
then
  echo "ERROR - Pub/Sub subscription '$SUBSCRIPTION_NAME' not found"
  exit 1
fi
echo "Pub/Sub subscription '$SUBSCRIPTION_NAME' exists."

# Test publishing a message to the topic
TEST_MESSAGE="Test message from validation script at $(date)"
gcloud pubsub topics publish "$TOPIC_NAME" --message="$TEST_MESSAGE" --project="$PROJECT" > /dev/null 2>&1

if [ $? -eq 0 ]
then
  echo "Successfully published test message to Pub/Sub topic."
else
  echo "WARNING - Failed to publish test message to Pub/Sub topic"
fi

echo "Step 3 of the validation passed. Pub/Sub resources are configured correctly."
echo ""
echo "All validation steps completed successfully!"
echo "============================================"
echo "GKE Cluster: $CLUSTER_NAME"
echo "App URL: http://$EXT_IP:$EXT_PORT"
echo "Pub/Sub Topic: $TOPIC_NAME"
echo "Pub/Sub Subscription: $SUBSCRIPTION_NAME"
echo "============================================"
