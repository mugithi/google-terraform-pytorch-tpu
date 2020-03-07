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

## Update NFS and MOUNT FS
sudo apt-get -y update 
sudo apt-get -y install nfs-common 
sudo mkdir -p $MOUNT_POINT
sudo mount ${NFS_IP}:/${SHARED_FS} $MOUNT_POINT 
echo "${NFS_IP}:/${SHARED_FS} $MOUNT_POINT nfs      defaults    0       0" | sudo tee -a /etc/fstab  
sudo chmod go+rw $MOUNT_POINT && df -kh 

## Checkout Tylans RoBERTa Repo
if [ -d "${MOUNT_POINT}/code" ];
then
  echo "using ${MOUNT_POINT}/code directory"
else
  mkdir -p ${MOUNT_POINT}/code
  git clone https://github.com/taylanbil/fairseq.git ${MOUNT_POINT}/code/fairseq 
fi

## Setup anaconda env
echo ". /anaconda3/etc/profile.d/conda.sh" >> ~/.bashrc
export PATH=/anaconda3/bin:$PATH
source ~/.bashrc
echo "*  soft    nofile       100000" | sudo tee -a /etc/security/limits.conf
echo "*  hard    nofile       100000" | sudo tee -a /etc/security/limits.conf 

## Git fetch and activate nightly
cd ${MOUNT_POINT}/code/fairseq 
git fetch 
git checkout roberta-tpu
conda activate torch-xla-nightly  
pip install --editable . 
pip install pyarrow

## Pull runme.sh and change_tpu_runtime.sh
cd ${MOUNT_POINT}/code/
gsutil cp ${SCRIPTS_URL}/runme.sh .
gsutil cp ${SCRIPTS_URL}/change_tpu_runtime.sh .
chmod u+x $MOUNT_POINT/code/runme.sh
chmod u+x $MOUNT_POINT/code/change_tpu_runtime.sh

## Download files to the local file
if [ -d "${MOUNT_POINT}/data" ];
then
   echo "you have data in the $MOUNT_POINT/data, directory, please confirm that you want to overwrite it"
else 
    mkdir -p $MOUNT_POINT/data 
    gsutil -m cp -r gs://tpu-demo-eu/dataset/* $MOUNT_POINT/data/
fi

# ./change_tpu_runtime.sh ${PROJECT_ID} ${ZONE} ${TPU_NAME} ${IMAGE_NIGHTLY}
${MOUNT_POINT}/code
conda activate torch-xla-nightly 
nohup ./runme.sh 32

# chmod a+x update_gcs.sh
# nohup ./update_gcs.sh


