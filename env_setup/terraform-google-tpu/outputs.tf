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

output "tpu_project" {
  value = split("/",module.tpu.id)[1]
}

output "tpu_zone" {
  value = split("/",module.tpu.id)[3]
}

output "tpu_name" {
  value = split("/",module.tpu.id)[5]
}

output "shared_fs" {
  value = module.filestore.filestore_name
}

output "nfs_ip" {
  value = module.filestore.filestore_ip
}

# output "dataset_bucket_url" {
#   value = module.gcs_buckets.url
# }

output "default_account" {
  value = data.google_compute_default_service_account.default.email
}


