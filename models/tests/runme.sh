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
#* See the License for the specific language governing permissions and
# * limitations under the License.
# 

source /tmp/values.env 

source /anaconda3/etc/profile.d/conda.sh

conda activate torch-xla-nightly

TPU_POD_NAME=${ENV_BUILD_NAME}-tpu

cd /usr/share/torch-xla-nightly/pytorch/xla/test/
python -m torch_xla.distributed.xla_dist \
        --tpu=$TPU_POD_NAME \
        --conda-env=torch-xla-nightly \
        --env=XLA_USE_BF16=1 \
        -- sudo python /usr/share/torch-xla-nightly/pytorch/xla/test/test_train_imagenet.py --fake_data

