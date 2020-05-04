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
  version  = "~> 3.9.0"
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  version  = "~> 3.9.0"
}

locals {
  compute_service_account = {
    email  = "default"
    scopes = "${var.service_account_scopes}"
  }
}

## Backend Initalize
terraform {
  backend "gcs" {}
}

data "google_compute_default_service_account" "default" {
  project = var.project_id
}


### Create Filestore 
module "filestore" {
  source           = "git::https://github.com/mugithi/terraform-google-filestore?ref=v1.0.0"
  project_id       = var.project_id
  zone             = var.zone
  filestore_name   = var.filestore_name
  tier             = "PREMIUM"
  capacity_gb      = 2560
  file_shares_name = var.tpu_shares_name
  network          = var.network
}

### Create TPU 
module "tpu" {
  source           = "git::https://github.com/mugithi/terraform-google-tpu?ref=v1.0.2"
  project_id       = var.project_id
  zone             = var.zone
  tpu_name         = var.tpu_name
  accelerator_type = var.accelerator_type
  network          = var.network
  cidr_block       = var.cidr_block
  pytorch_version  = var.pytorch_version
  preemptible      = false
}

# Supporting module to create container metadata
module "gce-container" {
  source  = "git::https://github.com/terraform-google-modules/terraform-google-container-vm?ref=v2.0.0"
  container = {
  image = "${var.nightly_image == "" ? "gcr.io/tpu-pytorch/xla:nightly" : "gcr.io/tpu-pytorch/xla:nightly_${var.nightly_image}"}" }
}

## Project Metadata
resource "google_compute_project_metadata" "default" {
  metadata = merge(map("NFS_IP", module.filestore.filestore_ip), map("SHARED_FS", module.filestore.filestore_name), map("PROJECT_ID", var.project_id), map("ZONE", var.zone), map("MOUNT_POINT", var.mount_point), map("TPU_NAME", module.tpu.tpu_name), map("TPU_ACCELERATOR_TYPE", var.accelerator_type), map("SCRIPTS_URL", "gs://${var.dataset_bucket_url}/scripts"), map("IMAGE_NIGHTLY", var.nightly_image))
}
