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

source /tmp/values.env

TPU_POD_NAME=${ENV_BUILD_NAME}-tpu

source /anaconda3/etc/profile.d/conda.sh

conda activate torch-xla-nightly

logfile=/tmp/"$(date +%Y%m%d)-roberta-podrun-8.txt"
nshards=0
num_cores=8
data_path="$MOUNT_POINT/shared_pd" #EDIT ME AS PER DATASET LOCATION
DATABIN=$(seq 0 $nshards | xargs -I{} echo $data_path/shard{} | tr "\n" ":")
# checkpoints_out=/tmp/checkpoints-roberta-$1
checkpoints_out=$MOUNT_POINT/nfs_share/models/roberta/checkpoints-roberta-${ENV_BUILD_NAME}

cd $MOUNT_POINT/nfs_share/model_code/

python -m torch_xla.distributed.xla_dist \
        --tpu=$TPU_POD_NAME \
        --conda-env=torch-xla-nightly\
        --env XLA_USE_BF16=1 \
        -- python $MOUNT_POINT/nfs_share/code/train.py \
        $DATABIN \
        --save-dir $checkpoints_out \
        --arch roberta_large \
        --optimizer adam \
        --adam-betas '(0.9, 0.98)' \
        --adam-eps 1e-06 \
        --clip-norm 1.0 \
        --lr-scheduler polynomial_decay \
        --lr 0.0004 \
        --warmup-updates 15000 \
        --max-update 1500000 \
        --log-format json \
        --log-interval 10 \
        --skip-invalid-size-inputs-valid-test \
        --task multilingual_masked_lm \
        --criterion masked_lm \
        --dropout 0.1 \
        --attention-dropout 0.1 \
        --weight-decay 0.01 \
        --sample-break-mode complete \
        --tokens-per-sample 512 \
        --total-num-update 1500000 \
        --multilang-sampling-alpha 0.7 \
        --no-epoch-checkpoints \
        --save-interval-updates 3000 \
        --validate-interval 5000 \
        --num-workers 4 \
        --update-freq `expr 4096 / $num_cores` \
        --valid-subset=valid \
        --train-subset=train \
        --input_shapes 2x512 \
        --num_cores=8 \
        --metrics_debug \
        --suppress_loss_report \
        --log_steps=10 &> $logfile #logstep=1 