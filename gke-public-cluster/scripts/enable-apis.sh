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

# This script checks to make sure that the pre-requisite APIs are enabled.

# Enable the Cloud Resource Manager API
# Enable the Kubernetes Engine API
# Enable the Stackdriver Logging API
# Enable the Stackdriver Monitoring API
# Enable the BigQuery API

gcloud services enable cloudresourcemanager.googleapis.com \
 container.googleapis.com \
 logging.googleapis.com \
 monitoring.googleapis.com \
 bigquery-json.googleapis.com
