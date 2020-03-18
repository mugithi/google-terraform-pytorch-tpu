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

variable "project_id" {
  default = ""
}

variable "region" {
  default = ""
}

variable "zone" {
  default = ""
}

variable "pytorch_proj_name" {
  default = ""
}

variable "network" {
  default = "default"
}

variable "accelerator_type" {
  default = "v3-8"
}

variable "mount_point" {
  default = ""
}

variable "nightly_image" {
  description = "Specify the nightly image, in the format YYYYMMDD, for example 20191204. If you leave this field blank, the latest nightly image will be used"
  default     = ""
}
variable "service_account_scopes" {
  default = ["cloud-platform", ]
}

variable "machine_type" {
  default = "n1-standard-16"
}

variable "access_config" {
  default = [{
    nat_ip       = ""
    network_tier = "PREMIUM"
  }]
}

variable "script_bucket_url" {
  default = ""
}


variable "tpu_shares_name" {
  default = ""
}