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
    sudo chmod a+w ${MOUNT_POINT}/shared_pd
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

## link docs here: http://www.openslr.org/12
## download LibriSpeech and tar to shared PD 

SOURCE=dev-clean
mkdir -p ${MOUNT_POINT}/shared_pd/source 

cd ${MOUNT_POINT}/shared_pd/source
wget http://www.openslr.org/resources/12/$SOURCE.tar.gz
tar -xvf $SOURCE.tar.gz 

cd ${MOUNT_POINT}/shared_pd/target  
sudo gsutil -m cp -r ${MOUNT_POINT}/shared_pd/source gs://${PROJECT_ID}-${ENV_BUILD_NAME}-dataset

######################################### End of Data Prep Scrpit #######################################
#########################################################################################################

cd / && sudo umount ${MOUNT_POINT}/shared_pd/