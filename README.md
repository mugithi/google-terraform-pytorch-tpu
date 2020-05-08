# Introduction 

This module builds off [PyTorch/XLA](https://github.com/pytorch/xla) and enables you to do build a TPU PyTorch Distributed training enviroment using [PyTorch/XLA](https://github.com/pytorch/xla) using Google Cloud Builder.

## What this module does

This module does the following 

1. Creates Cloud TPU pod 
2. Creates a NFS share to allow for the sharing of code between compute instances 
3. Creates a GCE MIG(MIG) based on size of Cloud TPU pod
3. Allows user to specify a script that is used to customize the image in the instance group
4. Create a shared persistant disk (PD) that is used to host the dataset used for training


# Build Commands

|Build Action |Cloud Build Command|
|:----------|:-------------|
| Initialize the enviroment  |`gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=initialize`|
| Build the entire enviroment |`gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=create`|
| Destroy the entire enviroment |`gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=destroy`|
| Update/create the TPU e.g move from v3-32, v3-128 |`gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=update,_TPU=true`|
| Destroy the Cloud TPU  |`gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=destroy,_TPU=true`|
| Update/create the MIGi.e #of instances, size of shared PD |`gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=update,_MIG=true`|
| Destroy Cloud MIG including the Shared_PD  |`gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=destroy,_MIG=true`|
| Update both Cloud TPU and MIG |`gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=update,_TPU=true,_MIG=true`|
| Destroy both Cloud TPU and MIG |`gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=destroy,_TPU=true,_MIG=true`|


<!-- ## Deployment Architecture Diagram -->
<!-- ![Terraform Cloud TPU deployment Architecture ](https://github.com/mugithi/google-terraform-pytorch-tpu/blob/master/scripts/tf_cloudtpu_pytorch_provisioning.png?raw=true "Deployment Architecture Diagram") -->

## 1. Getting started

Clone the repo to your local enviroment. 
```
git clone https://github.com/mugithi/google-terraform-pytorch-tpu.git
cd google-terraform-pytorch-tpu
```

## 2. Configure the environment: Enable the following services
```
gcloud services enable cloudbuild.googleapis.com \
                       compute.googleapis.com \
                       iam.googleapis.com \
                       tpu.googleapis.com \
                       file.googleapis.com 
```

## 3. Configure the environment: IAM Permissions 

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

## 4. Configure the environment: Modify the variables file

All the build variables are stored in the file `[values.env](values.env)`. Modify this values to customize the enviromnment  


## 3. Initializing the environment `_BUILD_ACTION=initialize`

In order to begin training, you first have to initiaze the environmnet using the comamnd `gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=initialize`


### 3a. What happens when you initialize the enviroment 

Initializing the enviroment creates GCS bucket to store both the configuration information and training information as follows

- tf_backend: TF state for filestore, cloud tpu, MIG
- tf_backend/workspace: Workspace to store enviromental variables used by Cloud Buld in values.env
- tf_backend/worksplace/env_setup/scripts/: Scripts used to modify the instance group
- tf_backend/worksplace/env_setup/models/: Scripts that are loaded at start time to configure the instance group for training for a particular model. It comes preloaded with RoBERTa on Fairseq
- tf_backend: model specific training scripts
- dataset: bucket to store the training dataset

Each version of the environment is tracked using the variable `ENV_BUILD_NAME` that is required to be unique to each build. In order to create seperate enviroments, a unique value in the `ENV_BUILD_NAME` is required. You can then run the initalization command again and build a new enviroment. 

It is recomended that you keep seperate versions of the cloned cloud build repo for each build. 

## 4. Build the entire enviroment `_BUILD_ACTION=create`

You can  create the enviroment using the command `gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=create` and destroy it using the command `gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=destroy`  

#### 4a. What happens when you build create the enviroment

Running this command creates Filestore, Cloud TPU and MIG

Please note that destroying the environment does not remove the GCS buckets. You can recreate the training enviroment by reruning the `_BUILD_ACTION=create` command.

## 5. Update/Create Cloud TPU  `_BUILD_ACTION=update,_TPU=true`

You can update or create a new Cloud TPU using the command `gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=update,_TPU=true`. 

#### 5a. What happens when you update the Cloud TPU

When this comamnd is run, a new Cloud TPU is created created or existing one is updated.

The update command comes in handy for situations where one needs to move from a v3-8 to a v3-128 (done by changing the `TPU_ACCELERATOR_TYPE="v3-32"` variable) or modify the Cloud TPU PyTorch version from torch-1.5 to torch nightly (done by changing cloud   `TPU_PYTORCH_VERSION="pytorch-1.5"` variable). This command can also be used to recreate the Cloud TPU after destroying it using the `gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=destroy,_TPU=true` command.

#### 5b. Modifying the Cloud TPU runtime

TODO: If you specify a specific GCE torch-nightly version denoted by the variable `GCE_IMAGE_VERSION="20200427"`, cloud build will configure the Cloud TPU runtime to match the MIG GCE image version. If no value is called out in the variable `GCE_IMAGE_VERSION=""`, the latest nightly version is used.

Please note that updating the Cloud TPU enviroment does not modify the MIGsize. In order changes in paralle to Cloud TPU and MIG, you would also need to use include both the TPU and MIG in the cloud build substitation as follows `_BUILD_ACTION=update,_TPU=true,_MIG=true`

## 6. Update/Create Cloud MIG  `_BUILD_ACTION=update,_MIG=true`

You can update or create a new Cloud MIG using the command `gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=update,_MIG=true`.  

#### 6a. What happens when you update the MIG
When this comamnd is run, a new MIG is created created or existing one is updated.

The update command comes in handy for situations where one needs to change the number of VMs in the MIG (done by changing the `TPU_ACCELERATOR_TYPE="v3-32"` variable) or change the size of the shared persistant disk that stores the training data (done by  `SHARED_PD_SIZE='1024'` variable)


#### 6b. Modifying the GCE Image version

If you specify a specific GCE torch-nightly version denoted by the variable `GCE_IMAGE_VERSION="20200427"` and set the pytorch version to nightly in the `TPU_PYTORCH_VERSION="pytorch-1.5"`, cloudbuild will provision a MIG using the torch-nightly specified GCE_IMAGE version. In all other cases, cloud build will use the latest nightly versionn.

Please note, in order changes in parallel to Cloud TPU and MIG, you would also need to use include both the TPU and MIG in the cloud build substitation as follows `_BUILD_ACTION=update,_TPU=true,_MIG=true`oying it using the `gcloud builds submit --config=cloudbuild.yaml . --substitutions _BUILD_ACTION=destroy,_TPU=true` command

