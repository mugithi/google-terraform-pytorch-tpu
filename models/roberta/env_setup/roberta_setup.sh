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
source /tmp/values.env

MIG=$MACHINE_TYPE-$ENV_BUILD_NAME-mig
MIG_MASTER=$(gcloud compute instance-groups list-instances $MIG --zone $ZONE --format="value(instance.scope().segment(2))" --limit=1)

## Things that only run in Master
if [ $HOSTNAME == $MIG_MASTER ]
then 
    ## Download and run 
    # Get fairseq and checkout roberta-tpu branch
    mkdir -p $MOUNT_POINT/nfs_share/code
    chmod go+rw $MOUNT_POINT/nfs_share/code
    git clone https://github.com/taylanbil/fairseq.git $MOUNT_POINT/nfs_share/code
    cd $MOUNT_POINT/nfs_share/code
    git fetch
    git checkout roberta-tpu
    ## Things that run in all the MIG instances
    # Install fairseq and pyarrow to default conda-env
    # All the training runs will be executed in this environment
    cd $MOUNT_POINT/nfs_share/code
    source /anaconda3/etc/profile.d/conda.sh
    conda activate torch-xla-nightly
    pip install --editable .
    pip install pyarrow
fi 