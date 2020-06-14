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
# setups NFS share and optional donwloads docker containers 

# Set Variables

PROJECT_ID=
ENV_BUILD_NAME=

sudo gsutil cp gs://${PROJECT_ID}-${ENV_BUILD_NAME}-tf-backend/workspace/values.env /tmp/
sudo gsutil cp gs://${PROJECT_ID}-${ENV_BUILD_NAME}-tf-backend/workspace/values.env.auto /tmp/

source /tmp/values.env
MIG=$MACHINE_TYPE-$ENV_BUILD_NAME-mig
MIG_MASTER=$(gcloud compute instance-groups list-instances $MIG --zone $ZONE --format="value(instance.scope().segment(2))" --limit=1)

SHARED_NFS_IP=$(gcloud filestore instances describe $PROJECT_ID-$ENV_BUILD_NAME-filestore --zone $ZONE --format="value(networks.ipAddresses[0])")

## Update NFS mountpoint 
sudo apt-get -y update 
sudo apt-get -y install nfs-common 
sudo mkdir -p $MOUNT_POINT/nfs_share
sudo mount ${SHARED_NFS_IP}:/${SHARED_FS} $MOUNT_POINT/nfs_share 
echo "${SHARED_NFS_IP}:/${SHARED_FS} $MOUNT_POINT/nfs_share nfs      defaults    0       0" | sudo tee -a /etc/fstab  
sudo chmod go+rw $MOUNT_POINT/nfs_share

## Download models folder to the NFS share, runs on only one host   
if [[ $HOSTNAME == $MIG_MASTER ]]
then 
    mkdir -p $MOUNT_POINT/nfs_share/models/
    sudo gsutil cp -r  gs://${PROJECT_ID}-${ENV_BUILD_NAME}-tf-backend/workspace/models/* $MOUNT_POINT/nfs_share/models/
fi 

## Download setup shared persistant disk, runs in all the hosts  
## If the shared PD is not attached, exit the script 
if [[ ! -b /dev/disk/by-id/google-shared-pd ]] 
then 
    echo -e "${RED}The shared PD is not attached to the managed instance group ${NC}"
    echo -e "${RED}Edit the ${GREEN}values.env${RED} file and change the ${GREEN}SHARED_PD_DISK_ATTACH${RED} value and change the value from ${GREEN}false${NC} to true${NC}"
    echo -e "${RED}Run rerun the ${GREEN}gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=update,_MIG=true${RED} again ${NC}"
    echo -e "${RED}Then attempt reruning the ${GREEN}data_prep_seed_shared_disk_pd.sh${NC}"
    exit 0
## If the shared is attached, and existing mount folder, reuse that folder 
elif [[ -b /dev/disk/by-id/google-shared-pd ]] && [[ -d ${MOUNT_POINT}/shared_pd ]] 
then 
    echo -e "${RED}Using existing disk ${NC}"
    sudo mount -o discard,defaults /dev/disk/by-id/google-shared-pd ${MOUNT_POINT}/shared_pd
    sudo chmod a+w ${MOUNT_POINT}/shared_pd
## If the shared is attached no  folder mount folder create  
elif [[ -b /dev/disk/by-id/google-shared-pd ]] && [[ ! -d ${MOUNT_POINT}/shared_pd ]]
then  
    sudo mkdir -p ${MOUNT_POINT}/shared_pd 
    sudo mount -o discard,defaults /dev/disk/by-id/google-shared-pd ${MOUNT_POINT}/shared_pd
    sudo chmod a+w ${MOUNT_POINT}/shared_pd
fi 

 
## Download Docker Containers 
#docker pull gcr.io/tpu-pytorch/xla:nightly_3.6
