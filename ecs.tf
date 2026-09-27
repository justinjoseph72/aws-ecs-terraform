
# -----------------------------------------------------------------------
# CloudWatch Log Group for the task's container logs
# -----------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "cl_log_group" {
  name              = "/ecs/${var.app_name}"
  retention_in_days = 14
}


# -----------------------------------------------------------------------
# ECS Cluster
# -----------------------------------------------------------------------
resource "aws_ecs_cluster" "this" {
  name = "${var.app_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# -----------------------------------------------------------------------
# IAM: Task Execution Role (lets Fargate pull the image & write logs)
# -----------------------------------------------------------------------
resource "aws_iam_role" "execution_role" {
  name = "${var.app_name}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "execution_role_policy" {
  role       = aws_iam_role.execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# -----------------------------------------------------------------------
# IAM: Task Role (permissions your APPLICATION code needs at runtime,
# e.g. S3, DynamoDB access — separate from the execution role above)
# -----------------------------------------------------------------------
resource "aws_iam_role" "task_role" {
  name = "${var.app_name}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Attach additional policies to aws_iam_role.task_role as needed, e.g.:
resource "aws_iam_role_policy_attachment" "task_role_s3" {
  role       = aws_iam_role.task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy" "task_metadata_read" {
  name = "${var.app_name}-ecs-describe"
  role = aws_iam_role.task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ecs:DescribeTasks", "ecs:DescribeTaskDefinition"]
      Resource = "*"
    }]
  })
}

# -----------------------------------------------------------------------
# Security Group for the ECS task
# -----------------------------------------------------------------------
resource "aws_security_group" "ecs_task_sg" {
  name        = "${var.app_name}-task-sg"
  description = "Security group for ${var.app_name} ECS Fargate task"
  vpc_id      = aws_vpc.ecs_learning_vpc.id

  ingress {
    description = "Allow inbound traffic on container port"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = var.ingress_cidr_blocks
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-task-sg"
  }
}

# -----------------------------------------------------------------------
# Task Definition
# -----------------------------------------------------------------------
resource "aws_ecs_task_definition" "this" {
  family                   = var.app_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name      = var.app_name
      image     = var.app_image
      essential = true

      portMappings = [
        {
          containerPort = var.app_port
          hostPort      = var.app_port
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.cl_log_group.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      environment = [
        { name = "MANAGEMENT_HEALTH_MONGODB_ENABLED", value = "false" },
      ]
    }
  ])
}

resource "aws_ecs_service" "this" {
  name            = "${var.app_name}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private_subnets[*].id
    security_groups  = [aws_security_group.ecs_task_sg.id]
    assign_public_ip = var.assign_public_ip

  }
  enable_execute_command = var.enable_execute_command
}