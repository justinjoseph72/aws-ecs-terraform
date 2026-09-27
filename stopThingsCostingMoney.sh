#!/usr/bin/env bash

terraform destroy -target=aws_ecs_service.this \
-target=aws_ecs_cluster.this \
-target=aws_vpc_endpoint.ecr_api \
-target=aws_vpc_endpoint.ecr_dkr \
-target=aws_vpc_endpoint.s3 \
-target=aws_vpc_endpoint.cloudwatch_logs \
--auto-approve