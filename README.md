# Introduction 

This module builds off [](https://github.com/pytorch/xla) and enables you to do build a  TPU PyTorch Distributed training enviroment using [PyTorch/XLA](https://github.com/pytorch/xla) to perform training using the RoBERTa Fairseq models. 

### What this module does
This module does the following 

1. Creates Cloud TPU POD using your configuratable accelerator with Image version specification ability
2. Creates a NFS share to allow share your dataset between your compute instances 
3. Seeds the NFS Share with training dataset specified GCS bucket
4. Builds an XLA docker container with FAIRseq modules and pushes it to GCR
5. Starts a GCE instance with FAIRsq Docker containers pre-loaded
6. TODO: Mounts NFS share to FAIRseq Docker Containers 
6. TODO: Manually or automatically kicks off RoBERTa training job

### Diagram 


## Getting started

Clone the repo to your local enviroment. 
```
git clone https://github.com/mugithi/google-terraform-pytorch-tpu.git . 
```

### Enable the following services
```
gcloud services enable cloudbuild.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable tpu.googleapis.com
gcloud services enable file.googleapis.com
```
### Configure Permissions and enable services 
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

### Configure the environment: Cloud Builder 

Seed the remote-builder container using cloudbuild. 

```
cd remote-buider
gcloud builds submit --config=cloudbuild.yaml .

```
### Configure the enviroment 

#### Configure environment: TPU 

Navigate to the root directory and modify the `cloudbuild.yml` file  variables below to configure the PyTorch TPU enviroment  
```
cd .. 
vi cloudbuild.yml
_USERNAME: <username>
_MOUNT_POINT: /mnt/common
_SHARED_FS: <file_system_name> #n eeds to be between 7 - 16 characters
_ZONE: europe-west4-a
_REGION: europe-west4
_PROJECT_ID: <project_id>
_IMAGE_NIGHTLY: ""
_PYTORCH_PROJ_NAME: ${PYTORCH_PROJ_NAME}
_ACCELERATOR_TYPE: v3-8
_MACHINE_TYPE: n1-standard-8
```

##### Configure GCS bucket and Github Repo

Modify the variables with the source of the training dataset and the code repo to be used in the training VM.

```
_GCS_DATASET: gs://<gcs_bucket_with_training_dataset>
_CODE_REPO: https://github.com/taylanbil/fairseq.git
```

### Deploying the enviroment. 
To deploy the enviroment, execute cloud build from the command line 

```
gcloud builds submit --config=cloudbuild.yaml .
```

This will launch cloud build, you can monitor the deployment in the Gcloud Cloud bashboard in this [link](https://console.cloud.google.com/cloud-build/builds?) 

A succesfull deplyment of the enviroment will result in the following output

```
Step #5 - "clean-up-gcs": Already have image (with digest): gcr.io/cloud-builders/gsutil
Step #5 - "clean-up-gcs":  export NFS_IP=10.232.62.106 
Step #5 - "clean-up-gcs":  export TPU_POD_NAME=pytorch-tpu-new-tpu-v3-32 
Step #5 - "clean-up-gcs":  export MOUNT_POINT=/mnt/common 
Step #5 - "clean-up-gcs":  export SHARED_FS=tpushare 
Step #5 - "clean-up-gcs":  export BUILD=b3484b2e-7b3a-40f8-bc53-15da7e98e57a 
Step #5 - "clean-up-gcs":  export PYTORCH_PROJ_NAME=pytorch-tpu-new 
Step #5 - "clean-up-gcs":  Jupyter URL:http://35.204.4xx8.xxx:8888
Step #5 - "clean-up-gcs":  Jupyter PASSWORD:b3484b2e-7b3a-40f8-bc53-15da7e98e57a 
Finished Step #5 - "clean-up-gcs"
PUSH
```

Click on the ***URL** generated by a succesfull deployment to access Jupyter Lab Notebook and use the generated ***PASSWORD*** to access the Jupyter lab. Navigate to the notebook called `PyTorch_RoBERTa_CloudTPU.ipynb`

Once you are ready to clean up the enviroment, re-run  `cloudbuild`. This will cause a tear down of the environment created in the intial run. 
 
```
gcloud builds submit --config=cloudbuild.yaml .
```

# TODO

- Add: Jypter Notebook functionality to manipute the runtime 
- Switch from GCE to GKE instances


 
