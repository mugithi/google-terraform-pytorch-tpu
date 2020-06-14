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

# Supporting module pull the GCE MIG MODULE to be used in Main.tf file

# Pull slave data from the mig

provider "google" {
  version = "~> 3.9.0"
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  version = "~> 3.9.0"
}

locals {
  compute_service_account = {
    email  = "default"
    scopes = "${var.service_account_scopes}"
  }
}

##  Initalize Backend
terraform {
  backend "gcs" {}
}

data "google_compute_instance_group" "slave" {
  self_link = "${module.mig-slave.self_link}"
}

data "google_compute_default_service_account" "default" {
  project = var.project_id
}

# Supporting module pull the GCE MIG MODULE to be used in Main.tf file
module "gce-mig" {
  source = "git::https://github.com/mugithi/terraform-google-vm?ref=v1.5.1"
}

## Create SLAVE MIG TEMPLATE
module "mig_slave_template" {
  source               = "./.terraform/modules/gce-mig/modules/instance_template"
  machine_type         = var.machine_type
  network              = var.network
  service_account      = local.compute_service_account
  name_prefix          = var.name_prefix 
  source_image_family  = var.source_image_family
  source_image_project = var.source_image_project
  source_image         = var.source_image
  tags                 = ["${var.tags}"]
  startup_script       = "${file(var.startup_script)}"
  disk_size_gb  = var.disk_size_gb
  disk_type = "pd-ssd"
  access_config = var.access_config
  additional_disks  = [
  { 
    source = var.shared_pd_disk_name
    auto_delete  = "false"
    boot         = "false"
    mode         = "READ_ONLY"
    device_name  = "shared-pd"
  }
]
}

## Create SLAVE
module "mig-slave" {
  source            = "./.terraform/modules/gce-mig/modules/mig"
  instance_template = module.mig_slave_template.self_link
  project_id        = var.project_id
  region            = var.region
  zone              = var.zone
  hostname          = var.name_prefix 
  target_size       = split("-", var.accelerator_type)[1] / 8
  network           = var.network
  subnetwork        = var.network
  update_policy     = var.update_policy
}
