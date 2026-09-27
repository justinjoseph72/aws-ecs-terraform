variable "creator_tag" {
  description = "Value of the Creator tag"
  type        = string
  default     = "ecs-tf-learning"
}

variable "running_profile" {
  description = "AWS profile to use when running terraform commands"
  type        = string
  default     = "admin-sso"
}

variable "aws_region" {
  description = "AWS region to deploy"
  type        = string
  default     = "eu-west-2"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

}

variable "azs" {
  description = "Availability zones to spread subnets across"
  type        = list(string)
  default     = ["eu-west-2a", "eu-west-2b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}


variable "project_name" {
  description = "Name prefix used for tagging resources"
  type        = string
  default     = "ecs-tf-learning"
}


variable "app_name" {
  description = "Name of the application to deploy"
  type        = string
  default     = "home-inventory-app"
}

variable "app_port" {
  description = "Port on which the application will listen"
  type        = number
  default     = 8080
}

variable "app_image" {
  description = "Docker image for the application"
  type        = string
  default     = "give me ecr image"
}

variable "ingress_cidr_blocks" {
  description = "CIDR blocks allowed to reach the container port directly (restrict this — e.g. your ALB's SG or your own IP/32)"
  type        = list(string)
  default     = ["0.0.0.0/0"] 
}

variable "desired_count" {
  description = "Number of tasks to run"
  type        = number
  default     = 1
}

variable "enable_execute_command" {
  description = "Enable ECS Exec for shell access into the running task (no SSH needed)"
  type        = bool
  default     = false
}

variable "assign_public_ip" {
  description = "Whether to assign a public IP to the task (only needed if task is in a public subnet with no NAT/VPC endpoints)"
  type        = bool
  default     = false
}

variable "task_cpu" {
  description = "Fargate task CPU units (256, 512, 1024, 2048, 4096)"
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "Fargate task memory in MB (must be valid for the chosen cpu value)"
  type        = string
  default     = "512"
}