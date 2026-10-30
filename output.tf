output "vpc_id" {
  value = aws_vpc.ecs_learning_vpc.id
}

output "public_subnet_ids" {
  value = aws_subnet.public_subnets[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private_subnets[*].id
}

output "ecs_cluster_arn" {
  value = aws_ecs_cluster.this.arn
}

output "ecs_service_arn" {
  value = aws_ecs_service.this.arn
}

output "ecs_service_name" {
  value = aws_ecs_service.this.name
}

output "ecs_task_arn" {
  value = aws_ecs_task_definition.this.arn
}

output "ecs_task_definition_arn" {
  value = aws_ecs_task_definition.this.arn
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "aws_vpc_endpoint_s3_id" {
  value = aws_vpc_endpoint.s3_endpoint.id
}

output "aws_vpc_endpoint_sts_id" {
  value = aws_vpc_endpoint.all_vpc_endpoint["sts"].id
}

output "aws_vpc_endpoint_ecr_api_id" {
  value = aws_vpc_endpoint.all_vpc_endpoint["ecr.api"].id
}

output "aws_vpc_endpoint_ecr_dkr_id" {
  value = aws_vpc_endpoint.all_vpc_endpoint["ecr.dkr"].id
}



output "mongodb_ec2_instance_id" {
  value = aws_instance.mongodb_instance.id
}
