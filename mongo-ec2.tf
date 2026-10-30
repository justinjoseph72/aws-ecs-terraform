data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-*-x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Private subnets in that VPC (identify them however you tag them)
data "aws_subnets" "private_subnets" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.ecs_learning_vpc.id]
  }

  tags = {
    Tier = "private"   # adjust to your tagging convention
  }
}

data "aws_subnet" "private_subnet" {
for_each = toset(data.aws_subnets.private_subnets.ids)
id = each.value
}

resource "aws_iam_role" "mongo_ssm_role" {
  name = "${var.project_name}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Name    = "${var.project_name}-ssm-role"
    Creator = var.creator_tag
  }
}

resource "aws_iam_role_policy_attachment" "mongo_ssm_core" {
  role       = aws_iam_role.mongo_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "mongo_ecr_read" {
     role       = aws_iam_role.mongo_ssm_role.name
     policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "mongo_ssm_profile" {
  name = "${var.project_name}-mongo-ssm-profile"
  role = aws_iam_role.mongo_ssm_role.name
}

resource "aws_instance" "mongodb_instance" {
  ami                    = data.aws_ami.latest_amazon_linux.id
  instance_type          = var.ec2_instance_type
  subnet_id              = values(data.aws_subnet.private_subnet)[0].id
  vpc_security_group_ids = [aws_security_group.vpec_sg_mongo.id]
  iam_instance_profile   = aws_iam_instance_profile.mongo_ssm_profile.name
  user_data                   = templatefile("${path.module}/mongo-init.sh.tfpl", {
    mongo_root_user     = var.mongo_root_user
    mongo_root_pass     = var.mongo_root_pass
    account_id = data.aws_caller_identity.current.account_id
    region     = data.aws_region.current.region   
    repo       = var.mongoDb_image
    tag        = "latest"
  })
  user_data_replace_on_change = true

  tags = {
    Name    = "${var.project_name}-mongodb-instance"
    Creator = var.creator_tag
  }
  lifecycle {
    precondition {
      condition     = length(data.aws_subnet.private_subnet) > 0
      error_message = "No private subnets found in ${aws_vpc.ecs_learning_vpc.id} with Tier=private."
    }
  }
}
