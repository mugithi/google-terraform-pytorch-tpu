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

set -x
# Set Variables
PROJECT_ID=$(curl "http://metadata.google.internal/computeMetadata/v1/project/attributes/PROJECT_ID" -H "Metadata-Flavor: Google")
ZONE=$(curl "http://metadata.google.internal/computeMetadata/v1/project/attributes/ZONE" -H "Metadata-Flavor: Google")
TPU_NAME=$(curl "http://metadata.google.internal/computeMetadata/v1/project/attributes/TPU_NAME" -H "Metadata-Flavor: Google")
IMAGE_NIGHTLY=$(curl "http://metadata.google.internal/computeMetadata/v1/project/attributes/IMAGE_NIGHTLY" -H "Metadata-Flavor: Google") 
MOUNT_POINT=$(curl "http://metadata.google.internal/computeMetadata/v1/project/attributes/MOUNT_POINT" -H "Metadata-Flavor: Google")
SHARED_FS=$(curl "http://metadata.google.internal/computeMetadata/v1/project/attributes/SHARED_FS" -H "Metadata-Flavor: Google") 
NFS_IP=$(curl "http://metadata.google.internal/computeMetadata/v1/project/attributes/NFS_IP" -H "Metadata-Flavor: Google")
SCRIPTS_URL=$(curl "http://metadata.google.internal/computeMetadata/v1/project/attributes/SCRIPTS_URL" -H "Metadata-Flavor: Google")
TPU_ACCELERATOR_TYPE=$(curl "http://metadata.google.internal/computeMetadata/v1/project/attributes/TPU_ACCELERATOR_TYPE" -H "Metadata-Flavor: Google")

## Add usr groups
sudo groupadd docker
sudo usermod -aG docker $USER

## Install Docker
apt-get update 
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent 
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt-get -y update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io


## Perform Docker pull 
if [ -z "$IMAGE_NIGHTLY" ];
then 
  docker pull gcr.io/tpu-pytorch/xla:nightly
else
  docker pull gcr.io/tpu-pytorch/xla:nightly_$IMAGE_NIGHTLY
fi 

mkdir -p $MOUNT_POINT

NFS_OPTS=rw,sync,no_subtree_check,insecure
docker volume create --driver local \
  --opt type=nfs --opt o=addr=$NFS_IP,$NFS_OPTS \
  --opt device=:$MOUNT_POINT $SHARED_FS

## Perform Docker pull 
if [ -z "$IMAGE_NIGHTLY" ];
then 
  docker run -it -v $SHARED_FS:$MOUNT_POINT gcr.io/tpu-pytorch/xla:nightly /bin/bash
else
  docker run -it -v $SHARED_FS:$MOUNT_POINT gcr.io/tpu-pytorch/xla:nightly_$IMAGE_NIGHTLY /bin/bash
fi 

