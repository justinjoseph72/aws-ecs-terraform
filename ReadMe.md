## Description

This module will create the following:
* VPC with private and public subnets in 2 AZs.
* Internet gateway.
* public and private route tables.
* ECS task which runs a provided image.
* EC2 instance which has a mongodb docker container running
* VPC endpoints requried for the ECS task and EC2 instances to run
* Security groups requried for ECS and Ec2
* IAM roles

The ECS task and EC2 instances are deployed in private subnet of the vpc

### Describe status

```
aws ecs describe-services \
  --cluster home-inventory-app-cluster \
  --services home-inventory-app-service \
  --query 'services[0].{status: status, desired: desiredCount, running: runningCount, pending: pendingCount}'
```

### Exec into the ecs task
Use the correct profile
```
aws ecs execute-command --cluster home-inventory-app-cluster --task <taskid> --container home-inventory-app --interactive --command '/bin/sh'
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
