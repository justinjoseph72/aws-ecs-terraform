## Description

This will create a new VPC and ecs cluster to run ecs task in private subnets


### Describe status

```
aws ecs describe-services \
  --cluster home-inventory-app-cluster \
  --services home-inventory-app-service \
  --query 'services[0].{status: status, desired: desiredCount, running: runningCount, pending: pendingCount}'
```


**Do this at the end to prevent cost money**

To stop the ECS cluster and vpc run the command

```
./stopThingsCostingMoney.sh
```

Another Ways to scale down the task

```
terraform apply -var="desired-count-0"
```

### Force Deploy
If the desired count is set back to 1, it will not pull the latest image from the ECR. we need to do the following

```
aws ecs update-service \
  --cluster home-inventory-app-cluster \
  --service home-inventory-app-service \
  --force-new-deployment
```

### Status check
The following command will get the status of the ECS cluster and service
```
./ecsStatus.sh
```

### Lambda function
It is supposed to make all the running serivices to desired count 0. Its not deployed and tested. 
Thinking about doing it in non vpc to save cost.
in vpc will require vpc endpoint

### ECS in private subnet
Requires the following 
* VPC interface endpoint for ECR api to get authentication token
* VPC interface endpoint for ECR dkr to download image
* VPC gateway endpoint for S3 to allow downloading of image layers
* Route table in private subnet for the gateway endpoint

 ### Issues
~~The Task is unable to pull image from ECR
Not able to get Authtoken so need to check if the I am role requires the role and then check if vpc endpoint is required.~~
The issue is resolved by deploying the ecs task in public subnet and enabling public ip on the task. This allowed the task to talk to ECR via internet gateway and download the image
