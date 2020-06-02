#!/bin/bash

#  Copyright 2018 Google LLC
# * Licensed under the Apache License, Version 2.0 (the "License");
# * you may not use this file except in compliance with the License.
# * You may obtain a copy of the License at
# *
# *      http://www.apache.org/licenses/LICENSE-2.0
# *
# * Unless required by applicable law or agreed to in writing, software
# * distributed under the License is distributed on an "AS IS" BASIS,
# * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#* See the License for the specific language governing permissions and
# * limitations under the License.

#### How to use this script
### 1. Download the data from GCS bucket
### 2. Prepare the data 
### 3. Push the prepared data back to the GCS bucket 
### 4. Enter the path parepared data the GCS bucket into the variable  GCS_DATASET="gs://tpu-demo-eu/dataset/*" in the file values.env
### 5. To grant access to the GCS bucket, use the instructions below 
####### export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format 'value(projectNumber)')
####### export COMPUTE_DEFAULT_SA_EMAIL=$PROJECT_NUMBER-compute@developer.gserviceaccount.com
####### gsutil iam ch serviceAccount:$COMPUTE_DEFAULT_SA_EMAIL:roles/storage.objectViewer $GCS_RAW_DATASET


source /tmp/values.env

echo -e "${RED}Hello World from the dataprep script${NC}"