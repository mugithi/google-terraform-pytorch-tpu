#!/bin/bash -xe 
source values.env
source values.env.auto 
USERNAME=${USERNAME:-admin}
REMOTE_WORKSPACE=${REMOTE_WORKSPACE:-/home/${USERNAME}/workspace}
GCLOUD=${GCLOUD:-gcloud}
INSTANCE_NAME=${SHARED_PD_DISK_NAME}-instance 



# fix issues related to google_compute_known_hosts permissions error
mkdir /builder/home/.ssh/ && touch /builder/home/.ssh/google_compute_known_hosts && chmod 644 /builder/home/.ssh/google_compute_known_hosts

${GCLOUD} config set compute/zone ${ZONE}

${GCLOUD} compute scp --compress --recurse --force-key-file-overwrite --strict-host-key-checking=no  \
       $(pwd)/values.env $(pwd)/values.env.auto $(pwd)/env_setup/scripts/* $(pwd)/models/* ${USERNAME}@${INSTANCE_NAME}:/tmp/

function cleanup {
        if [ "$?" == "0" ]
        then
            echo -e "$${GREEN}Succeeded with $${PROJECT_ID}-$${ENV_BUILD_NAME}-mig build operations $${NC}"
        else 
            echo -e "$${RED}Did not succeed with $${PROJECT_ID}-$${ENV_BUILD_NAME}-mig build operations $${NC}"
            exit 0
        fi
    }
    
trap cleanup EXIT
## ability to an orbitary number of commands formated as COMMAND1, COMMAND2 in remote-builder
for ((i=1; i<20; i++))
do
        COMMAND="COMMAND$i"
        if [ -z "${!COMMAND}" ]; then
            break
        else
            ${GCLOUD} compute ssh  --force-key-file-overwrite --strict-host-key-checking=no  \
                ${USERNAME}@${INSTANCE_NAME} -- ${!COMMAND}  
        fi
done

