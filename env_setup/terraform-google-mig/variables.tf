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

variable "network" {
  default = "default"
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

variable "source_image_family" {
  default = ""
}

variable "source_image_project" {
  default = ""
}

variable "source_image" {
  default = ""
}

variable "disk_size_gb" {
  default = ""
}

variable "update_policy" {
  description = "The rolling update policy. https://www.terraform.io/docs/providers/google/r/compute_region_instance_group_manager.html#rolling_update_policy"
  type = list(object({
    max_surge_percent       = number
    max_unavailable_percent = number
    min_ready_sec           = number
    minimal_action          = string
    type                    = string
  }))
  default = [ 
    { 
      max_surge_percent       = 100
      max_unavailable_percent = 100
      min_ready_sec           = 0 
      minimal_action          = "RESTART"
      type                    = "PROACTIVE"
    }
  ]
}

variable "protocol" {
  description = "tcp/udp/icmp"
  default     = "tcp"
}

variable "ports" {
  description = "list of ports to allow traffic"
  default     = ""
}

variable "source_ranges" {
  description = "list of source ip ranges"
  default     = ""
}

variable "tags" {
  description = "list of tags"
  default     = ""
}

variable "name_prefix" {
  default = ""
}

variable "accelerator_type" {
  default =""
}

variable "startup_script" {
  default =""
}

variable "shared_pd_disk_name" {
  default =""
}

variable "shared_pd_disk_type" {
  default =""
}

variable "shared_pd_disk_size" {
  default =""
}

variable "shared_pd_disk_create" {
  default = "false"
  description = "If set to create a shared pd, mount shaared pd to instance shared pd, else do not mount"
}