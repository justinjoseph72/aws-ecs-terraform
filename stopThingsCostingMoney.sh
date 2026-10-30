#!/usr/bin/env bash

terraform destroy -target=aws_ecs_service.this \
-target=aws_ecs_cluster.this \
-target=aws_vpc_endpoint.all_vpc_endpoint \
-target=aws_vpc_endpoint.s3_endpoint \
-target=aws_instance.mongodb_instance \
--auto-approve
