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

## Add usr groups
SHARED_FS=tpushare
MOUNT_POINT=/mnt/common
PYTORCH_PROJ_NAME=pytorch-project-mount
BUILD=5e452b42-a97c-40da-9a1a-5f2a5fc6ba34

sudo groupadd docker
sudo usermod -aG docker $USER

docker run -d -v ${SHARED_FS}:${MOUNT_POINT} --shm-size 16G --log-driver=gcplogs -p 8888:8888 gcr.io/$PYTORCH_PROJ_NAME/xla:$BUILD
