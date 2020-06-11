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

PROJECT_ID=
ENV_BUILD_NAME=

sudo gsutil cp gs://${PROJECT_ID}-${ENV_BUILD_NAME}-tf-backend/workspace/values.env /tmp/ 

source /tmp/values.env

SHARED_NFS_IP=$(gcloud filestore instances describe $PROJECT_ID-$ENV_BUILD_NAME-filestore --zone $ZONE --format="value(networks.ipAddresses[0])")

## Update NFS mountpoint 
sudo apt-get -y update 
sudo apt-get -y install nfs-common 
sudo mkdir -p $MOUNT_POINT/nfs_share
sudo mount ${SHARED_NFS_IP}:/${SHARED_FS} $MOUNT_POINT/nfs_share 
echo "${SHARED_NFS_IP}:/${SHARED_FS} $MOUNT_POINT/nfs_share nfs      defaults    0       0" | sudo tee -a /etc/fstab  
sudo chmod go+rw $MOUNT_POINT/nfs_share

## Update shared pd mountpoint 
mkdir -p $MOUNT_POINT/shared_pd
mount -o discard,defaults /dev/disk/by-id/google-shared-pd ${MOUNT_POINT}/shared_pd

df -kh

## Copy the Models to the NFS share
mkdir -p $MOUNT_POINT/nfs_share/models/
chmod go+rw $MOUNT_POINT/nfs_share/models/ 
gsutil cp -r gs://${PROJECT_ID}-${ENV_BUILD_NAME}-tf-backend/workspace/models/* $MOUNT_POINT/nfs_share/models/
