# Introduction 

This module builds off [](https://github.com/pytorch/xla) and enables you to do build a  TPU PyTorch Distributed training enviroment using [PyTorch/XLA](https://github.com/pytorch/xla) to perform training using the RoBERTa Fairseq models. 

### What this module does
This module does the following 

1. Creates Cloud TPU POD using your configuratable accelerator with Image version specification ability
2. Creates a NFS share to allow share your dataset between your compute instances 
3. Seeds the NFS Share with training dataset specified GCS bucket
4. Builds an XLA docker container with FAIRseq modules and pushes it to GCR
5. Starts a GCE instance with FAIRsq Docker containers pre-loaded
6. Mounts NFS share to FAIRseq Docker Containers 
7. Manually or automatically kicks off RoBERTa training job


### Diagram 

## Getting started
### Configure the enviroment 

### Configure Permissions

### Configure the environment: Cloud Build 

### Configure environment: PyTorch TPU 

##### Table with modifiable modules 

### Configure scripts to run 

### Running the enviroment 

# TODO

- Add: Jypter Notebook functionality to manipute the runtime 
- Switch from GCE to GKE instances


 