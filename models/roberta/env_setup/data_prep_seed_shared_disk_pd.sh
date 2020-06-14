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
echo -e "${RED}Hello World,  Insert your data prep scripts here ${NC}"
echo -e "${RED}Store temporary data in  "${MOUNT_POINT}"/shared_pd/  ${NC}"


sudo gsutil -m cp -r ${GCS_DATASET} ${MOUNT_POINT}/shared_pd/ 
######################################### End of Data Prep Scrpit #######################################
#########################################################################################################

cd / && sudo umount ${MOUNT_POINT}/shared_pd/