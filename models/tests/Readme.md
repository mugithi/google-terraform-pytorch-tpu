# Testing the enviroment 

Upon the deployment of the Cloud TPU enviroment using the Cloudbuild/Terraform automation tools, the enviroment comes preloaded with scripts test the enviroment. 

This script uses the preloaded imagenet model using synthetic data 

#### Running the test 

```bash
source /tmp/values.env
bash -xe $MOUNT_POINT/nfs_share/models/tests/runme.sh
```


#### 1. This script will do the following

- Set the conda enviroment to *`torch-xla-nightly`*
- Kick off a *`torch_xla.distributed.xla_dis`* distributed training using all the instances in the managed instance group with the following options
    - Use `/usr/share/torch-xla-nightly/pytorch/xla/test/test_train_imagenet.py` test imagenet script 
    - Use fake data 

#### 2. Monitoring Expected output 

#### 2a. You should observe *`torch_xla.distributed.xla_dis`* connect to all the instances, example below

```json
python -m torch_xla.distributed.xla_dist --tpu=20200430-tpu --conda-env=torch-xla-nightly --env=XLA_USE_BF16=1 -- python /usr/share/torch-xla-nightly/pytorch/xla/test/test_train_imagenet.py --fake_data
2020-06-11 20:48:38  [] Command to distribute: "python" "/usr/share/torch-xla-nightly/pytorch/xla/test/test_train_imagenet.py" "--fake_data"
2020-06-11 20:48:38  [] Cluster configuration: {client_workers: [{10.164.15.222, n1-standard-32, europe-west4-a, n1-standard-32-20200430-5dpf}, {10.164.0.11, n1-standard-32, europe-west4-a, n1-standard-32-20200430-0pvm}, {10.164.15.221, n1-standard-32, europe-west4-a, n1-standard-32-20200430-1zqq}, {10.164.15.223, n1-standard-32, europe-west4-a, n1-standard-32-20200430-4sxl}], service_workers: [{10.69.26.141, 8470, v3-32, europe-west4-a, pytorch-nightly, 20200430-tpu}, {10.69.26.139, 8470, v3-32, europe-west4-a, pytorch-nightly, 20200430-tpu}, {10.69.26.140, 8470, v3-32, europe-west4-a, pytorch-nightly, 20200430-tpu}, {10.69.26.138, 8470, v3-32, europe-west4-a, pytorch-nightly, 20200430-tpu}]}
```

#### 2b. You should observe training results stream to the console, example below

```json
....

2020-06-11 20:49:13 10.164.15.222 [0] | Training Device=xla:8/0 Step=0 Loss=6.87500 Rate=18.24 GlobalRate=18.24 Time=20:49:13
2020-06-11 20:49:13 10.164.15.11 [0] | Training Device=xla:7/0 Step=0 Loss=6.87500 Rate=18.19 GlobalRate=18.19 Time=20:49:13
2020-06-11 20:49:13 10.164.15.221 [0] | Training Device=xla:3/0 Step=0 Loss=6.87500 Rate=18.15 GlobalRate=18.15 Time=20:49:13
2020-06-11 20:49:13 10.164.15.223 [0] | Training Device=xla:6/0 Step=0 Loss=6.87500 Rate=18.18 GlobalRate=18.18 Time=20:49:13
```
