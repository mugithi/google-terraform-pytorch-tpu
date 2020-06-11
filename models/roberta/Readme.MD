# Training on RoBERTa

Upon the deployment of the Cloud TPU enviroment using the Cloudbuild/Terraform automation tools, the enviroment comes preloaded with scripts to quickly enable you to start training a RoBERTa model

There are two steps that need to be completed 

- Configuring the enviroment to train RoBERTa 
- Train the model 

## Configuring the enviroment to train RoBERTa 

Use the `roberta_setup_script' to prepare the enviroment for training 

```
source /tmp/values.env
bash -xe $MOUNT_POINT/nfs_share/models/roberta/env_setup/roberta_setup.sh
```

*#### This script will do the following* 
- From the Managed Instance Group machine you are currently logged in, create a path `$MOUNT_POINT/nfs_share/code` if it does not exist 
- Download the FAIRseq repo into the path *`$MOUNT_POINT/nfs_share/code`
- Remote SSH into every instance in the Managed Instance Group and install libraries required for RoBERTa to run  

### Training  RoBERTa 

Start the training by running this command 

```
bash -xe $MOUNT_POINT/nfs_share/models/roberta/training/runme.sh
```

*####This script will do the following*
- Set the conda enviroment to *`torch-xla-nightly`*
- Kick off a *`torch_xla.distributed.xla_dis`* distributed training using all the instances in the managed instance group with the following options
    - Use training data stored under the shared pd *`$MOUNT_POINT/shared_pd/`*
    - Save the training log file under path /tmp/ of each managed group instance 


### Monitoring Training Progress 

You can monitor training progress by reviweing the training log file under the *`/tmp/`* directory 

```
tail -f /tmp/*roberta-podrun*
````

