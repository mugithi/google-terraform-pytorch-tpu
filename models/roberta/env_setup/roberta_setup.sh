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

set -xe
# Set Variables
source values.env
source values.env.auto

## Things that only run in Master
if [ $HOSTNAME == $MIG_MASTER ]
then 
    ## Download and run 
    # Get fairseq and checkout roberta-tpu branch
    mkdir -p $MOUNT_POINT/nfs_share/code
    git clone https://github.com/taylanbil/fairseq.git $MOUNT_POINT/nfs_share/code
    cd $MOUNT_POINT/nfs_share/code
    git fetch
    git checkout roberta-tpu

    # Pull the models scripts
    mkdir -p $MOUNT_POINT/nfs_share/train
    gsutil cp gs://pytorch-tpu-new-20200428-tf-backend/workspace/models/* $MOUNT_POINT/nfs_share/train/ 

fi 

## Things that run in all the MIG instances
# Install fairseq and pyarrow to default conda-env
# All the training runs will be executed in this environment
source /anaconda3/etc/profile.d/conda.sh
conda activate torch-xla-nightly
pip install --editable .
pip install pyarrow
