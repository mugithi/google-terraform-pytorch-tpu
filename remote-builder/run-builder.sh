#!/bin/bash -xe

USERNAME=${USERNAME:-admin}
REMOTE_WORKSPACE=${REMOTE_WORKSPACE:-/home/${USERNAME}/workspace}
INSTANCE_NAME=${INSTANCE_NAME:-builder-$(cat /proc/sys/kernel/random/uuid)}
ZONE=${ZONE:-us-central1-f}
INSTANCE_ARGS=${INSTANCE_ARGS:---boot-disk-auto-delete}
GCLOUD=${GCLOUD:-gcloud}

# check if previous steps succeeded, if not exit
if [ "$(cat /workspace/vars/exit_status.vars)" != "exit 0" ]
then
    exit 0
fi

# Always delete instance after attempting build
function cleanup {
    echo "exit 1" > /workspace/vars/exit_status.vars 
    ${GCLOUD} compute instances delete ${INSTANCE_NAME} --quiet
    exit 0
}

mkdir /builder/home/.ssh/ && touch /builder/home/.ssh/google_compute_known_hosts && chmod 644 /builder/home/.ssh/google_compute_known_hosts
ls -al /builder/home/.ssh/google_compute_known_hosts


${GCLOUD} config set compute/zone ${ZONE}

KEYNAME=builder-key

# TODO Need to be able to detect whether a ssh key was already created
ssh-keygen -t rsa -N "" -f ${KEYNAME} -C ${USERNAME} || true
chmod 400 ${KEYNAME}*

cat > ssh-keys <<EOF
${USERNAME}:$(cat ${KEYNAME}.pub)
EOF

${GCLOUD} compute instances create \
       ${INSTANCE_ARGS} ${INSTANCE_NAME} \
       --metadata block-project-ssh-keys=TRUE \
       --metadata-from-file ssh-keys=ssh-keys

trap cleanup EXIT

## Wait for SSH to become avaiable 
NAT_IP=$(${GCLOUD} compute instances describe ${INSTANCE_NAME} --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
attempt_counter=0
max_attempts=10
until [ $(`ssh -q -o StrictHostKeyChecking=no ${USERNAME}@${NAT_IP} -i ./${KEYNAME}  exit` echo $?) == 0 ]; do
# until [ "$(nmap -Pn ${NAT_IP} -p 22 | grep -i 22 | awk '{print $3}')" == "ssh" ]; do
    if [ ${attempt_counter} -eq ${max_attempts} ];then
      echo "Max attempts reached" 
      exit 1
    fi
    printf '.'
    attempt_counter=$(($attempt_counter+1))
    sleep 5
done

${GCLOUD} compute scp --compress --recurse --verbosity=debug --force-key-file-overwrite --strict-host-key-checking=no \
       $(pwd) ${USERNAME}@${INSTANCE_NAME}:${REMOTE_WORKSPACE} \
       --ssh-key-file=${KEYNAME}  

## ability to an orbitary number of commands formated as COMMAND1, COMMAND2 in remote-builder
for ((i=1; i<20; i++))
do
        COMMAND="COMMAND$i"
        if [ -z "${!COMMAND}" ]; then
                break
        else
              ${GCLOUD} compute ssh --ssh-key-file=${KEYNAME} --verbosity=debug --force-key-file-overwrite --strict-host-key-checking=no \
                     ${USERNAME}@${INSTANCE_NAME} -- ${!COMMAND}  
        fi
done

