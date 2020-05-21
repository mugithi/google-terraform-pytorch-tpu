#!/bin/bash 
source values.env 
USERNAME=${USERNAME:-admin}
REMOTE_WORKSPACE=${REMOTE_WORKSPACE:-/home/${USERNAME}/workspace}
GCLOUD=${GCLOUD:-gcloud}
INSTANCE_NAME=${SHARED_PD_DISK_NAME}-instance 

# Always delete instance after attempting build
function cleanup {
    # if [ "$?" == "0" ]
    #   then 
    #   ${GCLOUD} compute images create ${INSTANCE_NAME} --source-disk ${INSTANCE_NAME} --source-disk-zone ${ZONE} --force
    # fi
    # ${GCLOUD} compute instances delete ${INSTANCE_NAME} --quiet
    # ${GCLOUD} compute firewall-rules delete ${INSTANCE_NAME}-allow-ssh --quiet 
    exit 0
}

trap cleanup EXIT

# fix issues related to google_compute_known_hosts permissions error
mkdir /builder/home/.ssh/ && touch /builder/home/.ssh/google_compute_known_hosts && chmod 644 /builder/home/.ssh/google_compute_known_hosts
# ls -al /builder/home/.ssh/google_compute_known_hosts

${GCLOUD} config set compute/zone ${ZONE}

# KEYNAME=builder-key

# # TODO Need to be able to detect whether a ssh key was already created
# ls -al
# ssh-keygen -t rsa -N "" -f ${KEYNAME} -C ${USERNAME} || true
# chmod 400 ${KEYNAME}*

# cat > ssh-keys <<EOF
# ${USERNAME}:$(cat ${KEYNAME}.pub)
# EOF

${GCLOUD} compute scp --compress --recurse  --force-key-file-overwrite --strict-host-key-checking=no \
       $(pwd)/values.env $(pwd)/env_setup/scripts $(pwd)/models ${USERNAME}@${INSTANCE_NAME}:/tmp/

## Wait for SSH to become avaiable 
# NAT_IP=$(${GCLOUD} compute instances describe ${INSTANCE_NAME} --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
# attempt_counter=0
# max_attempts=10
# until [ $(`ssh -q -o StrictHostKeyChecking=no ${USERNAME}@${NAT_IP}  exit` echo $?) == 0 ]; do
#     if [ ${attempt_counter} -eq ${max_attempts} ];then
#       echo "Max attempts reached" 
#       exit 1
#     fi
#     printf '.'
#     attempt_counter=$(($attempt_counter+1))
#     sleep 5
# done

## ability to an orbitary number of commands formated as COMMAND1, COMMAND2 in remote-builder
for ((i=1; i<20; i++))
do
        COMMAND="COMMAND$i"
        if [ -z "${!COMMAND}" ]; then
            break
        else
            ${GCLOUD} compute ssh  --force-key-file-overwrite --strict-host-key-checking=no \
                ${USERNAME}@${INSTANCE_NAME} -- ${!COMMAND}  
        fi
done

