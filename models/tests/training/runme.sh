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

## pull the envirom
source /tmp/values.env 

## Model Variables
TPU_POD_NAME=${ENV_BUILD_NAME}-tpu

## Source Anaconda and set to nightly
source /anaconda3/etc/profile.d/conda.sh
conda activate torch-xla-nightly

# Run the imagenet test script and synthetic data
cd /usr/share/torch-xla-nightly/pytorch/xla/test/
python -m torch_xla.distributed.xla_dist \
        --tpu=$TPU_POD_NAME \
        --conda-env=torch-xla-nightly \
        --env=XLA_USE_BF16=1 \
        -- python /usr/share/torch-xla-nightly/pytorch/xla/test/test_train_mp_imagenet.py --fake_data

## Clean up any running docker containers 
# COMMAND="docker rm $(docker ps -qa)"

# for instance in $(gcloud --project=${PROJECT_ID} \
#     compute instance-groups managed list-instances ${MIG} \
#     --zone=${ZONE} \
#     --format='value(NAME)[terminator=" "]')
# do  
#     gcloud compute ssh "$instance" \
#     --project=${PROJECT_ID} \
#     --zone=$ZONE \
#     --internal-ip \
#     --command="$COMMAND" \
#     --quiet 
# done


# python -m torch_xla.distributed.xla_dist \
#         --tpu=$TPU_POD_NAME --docker-image=gcr.io/tpu-pytorch/xla:nightly_3.6 
#         --docker-run-flag=--rm=true --docker-run-flag=--shm-size=50GB 
#         --env=XLA_USE_BF16=1 
#         -- python /pytorch/xla/test/test_train_mp_imagenet.py --fake_data
