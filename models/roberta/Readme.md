# Training on RoBERTa

Deploy the enviroment using the instructions in the [getting started guide](/Readme.md/#getting-started)

Upon the deployment of the Cloud TPU enviroment using the Cloudbuild/Terraform automation tools, the enviroment comes preloaded with scripts to quickly enable you to start training a RoBERTa model

There are three steps that need to be completed to start training. 

## 1. Prepare your data
---

#### 1. Updating/Initializing the shared persistent disk

Modify [values file](values.env) and set the [*__shared persistent disk__*](/values.env#L43) and [*__gcs training dataset__*](/values.env#L12) parameters. 

Modify the [`SHARED_PD_DISK_ATTACH=false`](/values.env#L44) variable and set it to **`true`**

Initialize the shared persistent disk using the command below.

```
gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=update,_DISK=true,_MIG=true
```

#### *1a. What happens when you initialize/update the shared persistent disk* 

Updating the shared persistent  disk, creates a shared persistent disk and seeds it with read only training using data from a GCS bucket specified by the `GCS_DATASET="gs://xxxxx/dataset/*` [variable](values.env#L18). This shared persistent disk is then mounted to all the GCE Instances

You also have the option of adding a running a data prepation step to the [data_prep_seed_shared_disk_pd.sh](/models/roberta/env_setup/data_prep_seed_shared_disk_pd.sh#L36) script before copying the data to the shared persistant disk.


## 2. Configuring the Cloud TPU enviroment to train RoBERTa 
---

Use the `roberta_setup_script` to prepare the enviroment for training 

```
source /tmp/values.env
nohup bash -xe $MOUNT_POINT/nfs_share/models/roberta/env_setup/roberta_setup.sh
```

#### 2a. This script will do the following
- From the Managed Instance Group machine you are currently logged in, create a path `$MOUNT_POINT/nfs_share/code` if it does not exist 
- Download the FAIRseq repo into the path *`$MOUNT_POINT/nfs_share/code`
- Remote SSH into every instance in the Managed Instance Group and install libraries required for RoBERTa to run  

### 3. Training  RoBERTa 
---

Start the training by running this command 

```
bash -xe $MOUNT_POINT/nfs_share/models/roberta/training/runme.sh &
```

#### 3b. This script will do the following
- Set the conda enviroment to *`torch-xla-nightly`*
- Using *`torch_xla.distributed.xla_dis`* launch a distributed training job connecting to all the instances in the managed instance group with the following options
    - Use training data stored under the shared pd *`$MOUNT_POINT/shared_pd/`*
    - Save the training log file under path /tmp/ of each managed group instance 


### 4. Monitoring Training Progress 
---

You can monitor training progress by reviweing the training log file under the *`/tmp/`* directory 

```
tail -f /tmp/*roberta-podrun*
````

