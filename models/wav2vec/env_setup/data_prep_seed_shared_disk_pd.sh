#!/bin/bash

#  Copyright 2018 Google LLC
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

source /tmp/values.env
set -xe 
## if the shared pd mount point does not exist, create it 
if [[ -z "$(findmnt /dev/disk/by-id/google-shared-pd)" ]] 
then 
    sudo mkfs.ext4 -m 0 -F -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/disk/by-id/google-shared-pd && \
    sudo mkdir -p ${MOUNT_POINT}/shared_pd && \
    sudo mount -o discard,defaults /dev/disk/by-id/google-shared-pd ${MOUNT_POINT}/shared_pd && \
    sudo chmod a+rwx ${MOUNT_POINT}/shared_pd
else 
    echo -e "${RED}/dev/disk/by-id/google-shared-pd already exist${NC}"
fi 

if [ -d "${MOUNT_POINT}/shared_pd" ]
then 
    echo -e "${RED}using existing ${MOUNT_POINT}/shared_pd directory ${NC}"
else 
    sudo mkdir -p ${MOUNT_POINT}/shared_pd
fi

#########################################################################################################
######################################## Data Prep Script ############################################### 
# links to datataset source here: http://www.openslr.org/12

mkdir -p ${MOUNT_POINT}/shared_pd/source 
MODEL_CODE_REPO="https://github.com/ultrons/fairseq.git"
MODEL_CODE_BRANCH='fairseq-dev'

## Clone the MODEL code to pull down the data preparation script  
mkdir -p ~/model_code
cd model_code
git clone $MODEL_CODE_REPO .
git fetch
git checkout $MODEL_CODE_BRANCH

### Prepare the data
# setup the python environment
source /anaconda3/etc/profile.d/conda.sh
conda activate torch-xla-nightly 

# Install dependancies 
sudo apt-get install -y  libsndfile1
pip install pysoundfile

# Download the data 
cd ${MOUNT_POINT}/shared_pd/source
curl -L http://www.openslr.org/resources/12/dev-clean.tar.gz | tar xzv
curl -L http://www.openslr.org/resources/12/test-clean.tar.gz | tar zxv 
curl -L http://www.openslr.org/resources/12/train-clean-100.tar.gz | tar zxv

# Run the data preperation script
python ~/model_code/examples/wav2vec/wav2vec_manifest.py ${MOUNT_POINT}/shared_pd/source/LibriSpeech --dest ${MOUNT_POINT}/shared_pd/source/LibriSpeech

######################################### End of Data Prep Scrpit #######################################
#########################################################################################################

cd / && sudo umount ${MOUNT_POINT}/shared_pd/