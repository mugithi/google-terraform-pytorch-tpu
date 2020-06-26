#!/bin/bash
#   This script does not clean after itself.


################### PARAMS BEGIN
VERSION=nightly
NCORES=$1
if [ -z $2 ]
then
  DATE=`date +%Y%m%d`
  echo "no date specified, using $DATE, and version $VERSION"
else
  DATE=$2
  echo "using $DATE, and version $VERSION"
fi
DISKIMG=debian-9-torch-xla-v$DATE
if [ -z $1 ]
then
  echo "give tpu cores as first arg"
  exit
fi
TASKNAME=vq-wav2vec
PROJECT=pytorch-tpu-new
MTYPE=n1-standard-64
SERVICEACCT=835981265219-compute@developer.gserviceaccount.com
ZONE=europe-west4-a
#DISKTYPE=pd-standard
DISKTYPE=pd-ssd
################### PARAMS END

set -e
set -x
# Create instance template
IT=$TASKNAME-it
# XXX: create resource
gcloud beta compute --project=$PROJECT instance-templates create $IT --machine-type=$MTYPE --network=projects/$PROJECT/global/networks/default --network-tier=PREMIUM --maintenance-policy=MIGRATE --service-account=$SERVICEACCT --scopes=https://www.googleapis.com/auth/cloud-platform --image=$DISKIMG --image-project=ml-images --boot-disk-size=200GB --boot-disk-type=$DISKTYPE --boot-disk-device-name=$IT --reservation-affinity=any

# create instance group
IG=$TASKNAME-ig
igsize=$(( NCORES / 8 ))

# XXX: create resource
gcloud compute --project=$PROJECT instance-groups managed create $IG --base-instance-name=$IG --template=$IT --size=$igsize --zone=$ZONE

# create TPU
TPU=$TASKNAME-tpu-$NCORES
# XXX: create resource
gcloud compute tpus create $TPU --zone=$ZONE --network=default --version=pytorch-$VERSION --accelerator-type=v3-$NCORES

# prepare vms
gcloud compute instance-groups managed wait-until-stable $IG --zone $ZONE
CONDAENV=torch-xla-$VERSION
copytimes=$(( NCORES / 32 ))
pids=
for instance in $(gcloud --project=$PROJECT compute instance-groups managed list-instances $IG --zone=$ZONE --format='value(NAME)[terminator=" "]')
do
  if [ -z $masterinstance ]
  then
    masterinstance=$instance
  fi
  gcloud compute ssh --project=$PROJECT --zone=$ZONE "$instance" --internal-ip  --command "
    if [ ! -d /tmp/data ]; then
      set -e
      set -x
      . /anaconda3/etc/profile.d/conda.sh
      conda activate $CONDAENV
      cd
      if [ ! -d fairseq ]; then
        git clone https://github.com/ultrons/fairseq.git -b fairseq-dev
      fi
      pip install pysoundfile
      sudo apt-get install -y  libsndfile1
      python3 -m pip install --upgrade cloud-tpu-client
      cd fairseq
      echo `pwd`
      python3 -m pip install --editable .
      mkdir -p /tmp/data/manifest
      cd /tmp/data
      bash ~/fairseq/examples/wav2vec/download-and-preprocess.sh ./manifest
    fi
" &
  pids+=" $!"
done
wait $pids || { echo "failed initializing vms" >&2; exit 1; }

echo $masterinstance
echo $instance
gcloud compute ssh --project=$PROJECT --zone=$ZONE $masterinstance --internal-ip --command "
  . /anaconda3/etc/profile.d/conda.sh
  conda activate $CONDAENV
  python -m torch_xla.distributed.xla_dist \
    --tpu=$TPU \
    --conda-env=$CONDAENV \
    --env XLA_USE_BF16=1 \
  -- python \
~/fairseq/train.py \
 /tmp/data/manifest \
         --tpu \
         --bf16 \
         --distributed-world-size 32 \
--max-sentences 8 \
--num-workers 6 \
--max-update 4000 \
--save-interval 1 \
--no-save \
--disable-validation \
--no-epoch-checkpoints \
--arch wav2vec \
--task audio_pretraining \
--lr 1e-06 \
--min-lr 1e-09 \
--optimizer adam \
--max-lr 1e-05 \
--lr-scheduler cosine \
--conv-feature-layers '[(512, 10, 5), (512, 8, 4), (512, 4, 2), (512, 4, 2), (512, 4, 2), (512, 1, 1), (512, 1, 1), (512, 1, 1)]' \
--conv-aggregator-layers '[(512, 2, 1), (512, 3, 1), (512, 4, 1), (512, 5, 1), (512, 6, 1), (512, 7, 1), (512, 8, 1), (512, 9, 1), (512, 10, 1), (512, 11, 1), (512, 12, 1), (512, 13, 1)]' \
        --activation gelu --offset auto --skip-connections-agg --residual-scale 0.5 \
        --combine-groups --vq-vars 320 --vq-temp '(2,0.5,0.999995)' --prediction-steps 12 --warmup-updates 1000 \
 --vq-type gumbel --vq-groups 2 --vq-depth 2 \
--log-compression \
--warmup-init-lr 1e-07 \
--criterion binary_cross_entropy \
--num-negatives 10 \
--max-sample-size 150000 \
        --max-tokens 300000 --cross-sample-negatives 0 --update-freq 1 --seed 2 --skip-invalid-size-inputs-valid-test \
--skip-invalid-size-inputs-valid-test \
--log-interval 20 \
--log-format simple
"

