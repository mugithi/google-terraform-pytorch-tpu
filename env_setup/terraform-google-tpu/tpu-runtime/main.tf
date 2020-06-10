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

##  Initalize Backend
terraform {
  backend "gcs" {}
}

## Create Instances
resource "google_compute_instance" "disk_instance" {
  name         = "${var.shared_pd_disk_name}-instance"
  machine_type = "n1-standard-8"
  zone         = var.zone
  tags = ["${var.tags}"]
  allow_stopping_for_update = true
  boot_disk {
    initialize_params {
      image = "ml-images/torch-xla"
    }
  }

  service_account {
    email  = "default"
    scopes = ["cloud-platform"]
  }

  network_interface {
    network = var.network
    access_config {
    }
  }
}

## Firewall
module "firewall" {
  source        = "git::https://github.com/mugithi/terraform-google-firewall-rules.git"
  network       = var.network
  protocol      = var.protocol
  ports         = ["${var.ports}"]
  source_ranges = ["${var.source_ranges}"]
  tags          = ["${var.tags}"]
}

