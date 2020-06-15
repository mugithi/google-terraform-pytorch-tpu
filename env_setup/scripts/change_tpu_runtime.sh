#!/bin/bash
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
source /anaconda3/etc/profile.d/conda.sh
conda activate torch-xla-1.5 
source /tmp/values.env
source /tmp/values.env.auto
python /tmp/change_tpu_runtime.py --tpu-name="${ENV_BUILD_NAME}"-tpu --target-version=pytorch-0.5-dev${GCE_IMAGE_VERSION}