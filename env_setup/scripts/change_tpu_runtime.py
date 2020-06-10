#  Copyright 2018 Google LLC
#
# * Licensed under the Apache License, Version 2.0 (the "License");
# * you may not use this file except in compliance with the License.
# * You may obtain a copy of the License at
# *
# *      http://www.apache.org/licenses/LICENSE-2.0
# *
# * Unless required by applicable law or agreed to in writing, software
# * distributed under the License is distributed on an "AS IS" BASIS,
# * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# * See the License for the specific language governing permissions and
# * limitations under the License.
# 
# Use with "pytorch-nightly" TPU version only
from cloud_tpu_client import Client
import argparse
parser = argparse.ArgumentParser()
parser.add_argument('--tpu-name', type=str, required=True, help='Name of the TPU Instance')
parser.add_argument('--target-version', type=str, required=True, help='Target TPU Runtime version')
args = parser.parse_args()
c = Client(args.tpu_name)
c.configure_tpu_version(args.target_version)
c.wait_for_healthy()