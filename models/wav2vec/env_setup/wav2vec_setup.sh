# 
# set -xe
# Set Variables
source /tmp/values.env
MIG=$MACHINE_TYPE-$ENV_BUILD_NAME-mig
# MIG_MASTER=$(gcloud compute instance-groups list-instances $MIG --zone $ZONE --format="value(instance.scope().segment(2))" --limit=1)

##### Variables 

## MODEL CODE REPO 
MODEL_CODE_REPO="https://github.com/ultrons/fairseq.git"
MODEL_CODE_BRANCH='fairseq-dev'

############################################################
#####  Things that only run in one host ####################
############################################################

## Fix permissions in the NFS share 
sudo chown -R $USER:$USER $MOUNT_POINT/nfs_share/
sudo chmod a+rw -R $MOUNT_POINT/nfs_share/


## Clone the MODEL code to the NFS share, for example fairseq  
if [[ -d $MOUNT_POINT/nfs_share/model_code ]]
then 
    rm -rf $MOUNT_POINT/nfs_share/model_code
fi
mkdir -p $MOUNT_POINT/nfs_share/model_code
chmod a+rwx $MOUNT_POINT/nfs_share/model_code
cd $MOUNT_POINT/nfs_share/model_code
git clone $MODEL_CODE_REPO .
cd $MOUNT_POINT/nfs_share/model_code
git fetch
git checkout $MODEL_CODE_BRANCH

############################################################
#####  Things that install on all the hosts ###################
############################################################

# Model specific dependancies 

COMMAND="
sudo chmod a+rw -R $MOUNT_POINT/nfs_share/ && \
cd '$MOUNT_POINT'/nfs_share/model_code && \
source /anaconda3/etc/profile.d/conda.sh && \
conda activate torch-xla-nightly && \
pip install pyarrow && \
pip install --editable . && \
sudo apt-get install -y  libsndfile1 && \
pip install pysoundfile
"

for instance in $(gcloud --project=${PROJECT_ID} \
    compute instance-groups managed list-instances ${MIG} \
    --zone=${ZONE} \
    --format='value(NAME)[terminator=" "]')
do  
    gcloud compute ssh "$instance" \
    --project=${PROJECT_ID} \
    --zone=$ZONE \
    --internal-ip \
    --command="$COMMAND" \
    --quiet
done