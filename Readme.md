# Introduction 

This module builds off [PyTorch/XLA](https://github.com/pytorch/xla) and enables you to reliabliy instatiate a  [PyTorch Distributed Cloud TPU training enviroment](https://github.com/pytorch/xla#-how-to-run-on-tpu-pods-distributed-training) using Google Cloud Builder.

### What this module does
---

This module does the following 

1. Creates Cloud TPU pod 
2. Creates a NFS share to allow for the sharing of code between compute instances 
3. Creates a GCE Managed Instance Group (MIG) based on size of Cloud TPU pod
3. Allows user to specify a script that is used to customize the image in the instance group
4. Create a shared persistent disk (PD) that is used to host the dataset used for training
5. Allows the user to specificy a script to prepare the data before loading it to the shared persistant disk


# Build Commands

|Build Action |Cloud Build Command|
|:----------|:-------------|
| Initialize the enviroment  | *[gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=initialize](https://github.com/mugithi/google-terraform-pytorch-tpu#3-initialize-the-training-environment)* |
| Initialize the shared persistent disk  | *[gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=initialize,_DISK=true](https://github.com/mugithi/google-terraform-pytorch-tpu#4-initialize-the-shared-persistent-disk)* |
| Create the enviroment | *[gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=create](https://github.com/mugithi/google-terraform-pytorch-tpu#5-create-the-enviroment)* |
| Destroy the enviroment | *[gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=destroy](https://github.com/mugithi/google-terraform-pytorch-tpu#6-destroy-the-enviroment)* |
| Update Cloud TPU | *[gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=update,_TPU=true](https://github.com/mugithi/google-terraform-pytorch-tpu#1-updating-cloud-tpu-pod)* |
| Destroy Cloud TPU  | *[gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=destroy,_TPU=true](https://github.com/mugithi/google-terraform-pytorch-tpu#1-updating-cloud-tpu-pod)* |
| Update the MIG | *[gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=update,_MIG=true](https://github.com/mugithi/google-terraform-pytorch-tpu#3-updating-the-managed-instance-group-mig)* |
| Destroy the MIG | *[gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=destroy,_MIG=true](https://github.com/mugithi/google-terraform-pytorch-tpu#3-updating-the-managed-instance-group-mig)* |
| Update shared persistent disk | *[gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=update,_DISK=true,_MIG=true](https://github.com/mugithi/google-terraform-pytorch-tpu#2-updating-the-shared-persistent-disk)* |
| Destroy shared persistent disk | *[gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=destroy,_DISK=true](https://github.com/mugithi/google-terraform-pytorch-tpu#2-updating-the-shared-persistent-disk)* |


# Deployment Architecture Diagram
![Terraform Cloud TPU deployment Architecture](docs/pytorch_gce_instances.png "Deployment Architecture Diagram")

# Getting Started 

#### 1. Enable the GCP services
---

Clone the repo to your local enviroment. 
```
git clone https://github.com/mugithi/google-terraform-pytorch-tpu.git
cd google-terraform-pytorch-tpu
```
Enable GCP services using the following command 
```
gcloud services enable cloudbuild.googleapis.com \
                       compute.googleapis.com \
                       iam.googleapis.com \
                       tpu.googleapis.com \
                       file.googleapis.com 
```

#### 2. Enable IAM Permissions 
---

```
export PROJECT=$(gcloud info --format='value(config.project)')
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT --format 'value(projectNumber)')
export CB_SA_EMAIL=$PROJECT_NUMBER@cloudbuild.gserviceaccount.com
gcloud projects add-iam-policy-binding $PROJECT --member=serviceAccount:$CB_SA_EMAIL --role='roles/iam.serviceAccountUser' 
gcloud projects add-iam-policy-binding $PROJECT --member=serviceAccount:$CB_SA_EMAIL  --role='roles/compute.admin' 
gcloud projects add-iam-policy-binding $PROJECT --member=serviceAccount:$CB_SA_EMAIL  --role='roles/iam.serviceAccountActor' 
gcloud projects add-iam-policy-binding $PROJECT --member=serviceAccount:$CB_SA_EMAIL  --role='roles/file.editor'  
gcloud projects add-iam-policy-binding $PROJECT --member=serviceAccount:$CB_SA_EMAIL  --role='roles/compute.securityAdmin'
gcloud projects add-iam-policy-binding $PROJECT --member=serviceAccount:$CB_SA_EMAIL  --role='roles/storage.admin'
gcloud projects add-iam-policy-binding $PROJECT --member=serviceAccount:$CB_SA_EMAIL  --role='roles/tpu.admin'
```


#### 3. Initialize the training environment 
---

Modify [values file](values.env) and set the *__training environment build id__* and *__project values__*. Initialize the enviroment using the command below. 

```
gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=initialize
```

#### *3a. What happens when you initialize the enviroment* 

Initializing the traning enviroment creates GCS bucket to store both the configuration information and training information as follows

- tf_backend: TF state for filestore, cloud tpu, mig
- tf_backend/workspace: Workspace to store enviromental variables used by Cloud Buld in values.env
- tf_backend/worksplace/env_setup/scripts/: Scripts used to modify the instance group
- tf_backend/worksplace/env_setup/models/: Scripts that are loaded at start time to configure the instance group for training for a particular model. It comes preloaded with RoBERTa on Fairseq
- tf_backend: model specific training scripts
- dataset: bucket to store the training dataset

Each version of the environment is tracked using the variable `ENV_BUILD_NAME` unique to each environment. In order to create seperate enviroments, a specify a new `ENV_BUILD_NAME`.

It is recomended that you keep seperate versions of the cloned cloud build repo for each environment to easily allow to easily version your scripts and [variable](values.env) file. 


#### 4. Create the enviroment 
---

Modify [values file](values.env) and set the *__cloud TPU__*, *__managed instance group__* and *__shared nfs__* parameters. Create the training enviroment using the command below. 

```
gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=create
``` 
#### *4a. What happens when you build create the enviroment*

Running this command creates Filestore, Cloud TPU and Managed Instance Group using values in the [variable](values.env) file. 


#### *4b. Troubleshooting Creating the Shared Enviroment*

Please note that if the `SHARED_PD_DISK_ATTACH` [variable](values.env#L44) is set to `true` and the Shared persistant disk is not initialized, you will see the error **resourceNotFound**. 

`Step #5 - "terraform-google-mig": Step #1 - "terraform-google-mig": Error: Error creating InstanceGroupManager: googleapi: Error 404: The resource 'projects/pytorch-tpu-cb-test/zones/europe-west4-a/disks/pd-ssd-2055-20
200430' was not found, notFound`

In order to resolve this error, change the `SHARED_PD_DISK_ATTACH` [variable](values.env#L44) to `false` or create the Shared Persistant Disk using the command `_BUILD_ACTION=create,_DISK=true`


# Training
---

After initialzing the environment, you can bigin training your PyTorch models on Cloud TPU. The following example models are made avaiable for you to start with as part of this repo.

- [Test model using ImageNet and Synethetic Data](models/tests) 
- [RoBERTa model on FAIRseq](models/roberta) 
- [COMMING SOON: Wave2vec model on FAIRseq]()


# Updating the environment 

#### 1. Initializing/Updating the shared persistent disk
---
Modify [values file](values.env) and set the [*__shared persistent disk__*](values.env#L43) and [*__gcs training dataset__*](values.env#L12) parameters. Initialize the shared persistent disk using the command below.

```
gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=update,_DISK=true,_MIG=true
```

#### *1a. What happens when you initialize/Update the shared persistent disk* 

When you run the `_BUILD_ACTION=update,_DISK=true` command,

- A new persistant disk is created if non exists. If one exists, it is destroyed and new one is created
- This disk is mounted to a temporary GCE instance that runs any data preparation as specified in the [data_prep_seed_shared_disk_pd.sh](env_setup/data_prep_seed_shared_disk_pd.sh#L36) 
- The new disk is formated in ext4 and mounted it in path specified in the `$MOUNT_POINT/shared_pd` as specified in the mount point  [variable](values.env#L10) file
- Mounts the new shared persistent to the managed instance group as read only volume. 

The update command `_BUILD_ACTION=update,_DISK=true` can be used to reload new training data into the shared persistent disk. 

#### *3c. Troubleshooting Shared persistent Disk*

Please note that updates to the shared persistent disk will only take place if you change its changing the `SHARED_PD_DISK_SIZE="XXXX"` [variable](values.env). If you do not change the size of the persistent disk when running an update, you will see the error.

`Step #1 - "terraform-google-disk": Step #0 - "terraform-google-disk-seed": Error: Error creating instance: googleapi: Error 400: The disk resource 'projects/xxxx' is already being used by 'projects/xxxx', resourceInUseByAnotherResource`

#### 2. Updating Cloud TPU pod 
---

```
gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=update,_TPU=true
``` 

#### *2a. What happens when you update the Cloud TPU*

When this comamnd is run, a new Cloud TPU is created created or existing one is updated.

The update command can be used to upgrade from a v3-8 to a v3-128 by changing the `TPU_ACCELERATOR_TYPE="v3-32"` [variable](values.env#L23) or Cloud TPU PyTorch version from torch-1.5 to torch nightly by changing cloud `TPU_PYTORCH_VERSION="pytorch-1.5"`  [variable](values.env#L24). 

The update command can also be used to recreate the Cloud TPU after destroying it using the `gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=destroy,_TPU=true` command.

#### *2b. Modifying the Cloud TPU runtime*

If you specify a specific GCE torch-nightly version using the `GCE_IMAGE_VERSION="20200427"` [variable](values.env#L29), cloud build will configure the Cloud TPU runtime to match the MIG GCE image version. If no value is called out in the `GCE_IMAGE_VERSION=""` [variable](values.env#L29) , the latest nightly version is used.

Please note that updating the Cloud TPU pod does not modify the MIG. In order to change both the Cloud TPU and MIG, they both need to be explicity included in the cloud build substitation as follows `_BUILD_ACTION=update,_TPU=true,_MIG=true`

#### 3. Updating the Shared Persistent Disk 
---

```
gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=update,_DISK=true,_MIG=true
``` 



#### 4. Updating the Managed Instance Group MIG
---

```
gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=update,_MIG=true
```  

#### *4a. What happens when you update the MIG*
When this comamnd is run, a new MIG is created created or existing one is updated.

The update command can be used to change the number of VMs in the MIG by changing the `TPU_ACCELERATOR_TYPE="v3-32"` [variable](values.env#L23) or size of the shared persistent disk that stores the training data by changing the `SHARED_PD_DISK_SIZ='1024'` [variable](values.env#L45)

#### *4b. Modifying the GCE Image version*

If you specify a specific GCE torch-nightly using the `GCE_IMAGE_VERSION="20200427"` [variable](values.env#L29) and set the pytorch version in the  `TPU_PYTORCH_VERSION="pytorch-1.5"` [variable](values.env#L24), cloudbuild will provision a MIG using the torch-nightly specified GCE_IMAGE version. In all other cases, cloud build will use the latest nightly versionn.

Please note that updating the Cloud TPU enviroment does not modify the MIG size. In order to change both the Cloud TPU and MIG, they both need to be explicity included in the cloud build substitation as follows `_BUILD_ACTION=update,_TPU=true,_MIG=true`

# Destroy the enviroment 
---

```
gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=destroy
``` 

Please note that destroying the environment using does not remove the GCS buckets and shared persistent disk. You can recreate the training enviroment by simply reruning the `_BUILD_ACTION=create` command.

#### *1a. Destroying the entire environment ie. Starting Over*

In order to completly destroy the entire enviroment, you need to run the above step and then destroy the shared persistant disk and GCS buckets

In order to delete the shared persistant disk run the command below 

```
gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=destroy,_DISK=true
``` 

#### *1b. Destroying GCS buckets*

In order to delete the GCS buckets, navigate to the GCS in the [Google Cloud Console](https://console.cloud.google.com/storage?_ga=2.77017180.85729593.1591821429-1948326961.1590547304) and delete the buckets titled 

- your_project_id*-dataset 
- your_project_id*-tf-backend
