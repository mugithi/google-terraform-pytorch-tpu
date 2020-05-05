/**
 * Copyright 2018 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


provider "google" {
  version = "~> 3.9.0"
  project = var.project_id
}

provider "google-beta" {
  version = "~> 3.9.0"
  project = var.project_id
}

data "google_compute_default_service_account" "default" {
  project = var.project_id
}

### Create GCS BUCKET 
module "gcs_buckets" {
  source          = "terraform-google-modules/cloud-storage/google"
  version         = "~> 1.3"
  project_id      = var.project_id
  names           = ["${var.gcs_tf_backend}", "${var.gcs_dataset}"]
  set_admin_roles = true
  admins          = ["serviceAccount:${data.google_compute_default_service_account.default.email}"]
  prefix          = ""
  versioning = {
    "${var.gcs_tf_backend}" = true
    "${var.gcs_dataset}"    = true

  }
  force_destroy = {
    "${var.gcs_tf_backend}" = false
    "${var.gcs_dataset}"    = false
  }
}
