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
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  version = "~> 3.9.0"
}

provider "random" {
  version = "~> 2.1.2"
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