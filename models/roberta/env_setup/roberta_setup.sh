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
# set -xe
# Set Variables
source /tmp/values.env
MIG=$MACHINE_TYPE-$ENV_BUILD_NAME-mig
# MIG_MASTER=$(gcloud compute instance-groups list-instances $MIG --zone $ZONE --format="value(instance.scope().segment(2))" --limit=1)

##### Variables 

## ENV SETUP GITHUB REPO 
ENV_SETUP_REPO=' https://github.com/mugithi/google-terraform-pytorch-tpu.git'
ENV_SETUP_BRANCH='master'

## MODEL CODE REPO 
MODEL_CODE_REPO="https://github.com/taylanbil/fairseq.git"
MODEL_CODE_BRANCH='synth-data-roberta'

############################################################
#####  Things that only run in one host ####################
############################################################

## Fix permissions in the NFS share 
sudo chown -R $USER:$USER $MOUNT_POINT/nfs_share/


# Clone the Enviroment SETUP code to the NFS share, for example for RoBERTa 
if [[ -d $MOUNT_POINT/nfs_share/env ]]
then 
    rm -rf $MOUNT_POINT/nfs_share/env
fi

mkdir -p $MOUNT_POINT/nfs_share/env
chmod go+rw $MOUNT_POINT/nfs_share/env
cd $MOUNT_POINT/nfs_share/env
git clone $ENV_SETUP_REPO . 
git fetch 
git checkout $ENV_SETUP_BRANCH 


## Clone the MODEL code to the NFS share, for example fairseq  
if [[ -d $MOUNT_POINT/nfs_share/model_code ]]
then 
    rm -rf $MOUNT_POINT/nfs_share/model_code
fi
mkdir -p $MOUNT_POINT/nfs_share/model_code
chmod go+rw $MOUNT_POINT/nfs_share/model_code
cd $MOUNT_POINT/nfs_share/model_code
git clone $MODEL_CODE_REPO .
cd $MOUNT_POINT/nfs_share/model_code
git fetch
git checkout $MODEL_CODE_BRANCH


############################################################
#####  Things that only on all the hosts ###################
############################################################

# Model specific dependancies 

COMMAND="
cd '$MOUNT_POINT'/nfs_share/model_code && \
source /anaconda3/etc/profile.d/conda.sh && \
conda activate torch-xla-nightly && \
pip install --editable . && \
pip install pyarrow
"

for instance in $(gcloud --project=${PROJECT_ID} \
    compute instance-groups managed list-instances ${MIG} \
    --zone=${ZONE} \
    --format='value(NAME)[terminator=" "]')
do  
    gcloud compute ssh "$instance" \
    --project=${PROJECT_ID} \
    --zone=$ZONE \
    --internal-ip \
    --command="$COMMAND" \
    --quiet 
done
