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

output "aws_vpc_endpoint_ecr_api_id" {
  value = aws_vpc_endpoint.ecr_api.id
}

output "aws_vpc_endpoint_ecr_api_network_interface_ids" {
  value = aws_vpc_endpoint.ecr_api.network_interface_ids
}

output "aws_vpc_endpoint_ecr_dkr_id" {
  value = aws_vpc_endpoint.ecr_dkr.id
}

output "aws_vpc_endpoint_ecr_dkr_network_interface_ids" {
  value = aws_vpc_endpoint.ecr_dkr.network_interface_ids
}

output "aws_vpc_endpoint_s3_id" {
  value = aws_vpc_endpoint.s3.id
}

output "aws_vpc_endpoint_cloudwatch_logs_id" {
  value = aws_vpc_endpoint.cloudwatch_logs.id
}

output "aws_vpc_endpoint_cloudwatch_logs_network_interface_ids" {
  value = aws_vpc_endpoint.cloudwatch_logs.network_interface_ids
}
