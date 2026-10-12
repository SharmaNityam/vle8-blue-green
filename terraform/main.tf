terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    local = {
      source = "hashicorp/local"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# Latest Ubuntu 22.04 LTS AMI, published by Canonical
data "aws_ssm_parameter" "ubuntu_2204" {
  name = "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_caller_identity" "me" {}

resource "aws_security_group" "jenkins_sg" {
  name        = "vle8-bluegreen-sg"
  description = "VLE-8 Blue-Green deployment"
  vpc_id      = data.aws_vpc.default.id

  dynamic "ingress" {
    for_each = {
      22   = "SSH"
      8080 = "Jenkins"
      8000 = "myapp-service (live traffic)"
      8001 = "myapp-green-preview (test Green)"
    }
    content {
      description = ingress.value
      from_port   = ingress.key
      to_port     = ingress.key
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidrs
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vle8-bluegreen-sg"
  }
}

# Ansible connects over AWS Systems Manager (no SSH); the SSM connection
# plugin moves files through this bucket.
resource "aws_s3_bucket" "ansible_ssm" {
  bucket        = "vle8-ansible-ssm-${data.aws_caller_identity.me.account_id}"
  force_destroy = true
}

resource "aws_iam_role" "ssm_role" {
  name = "vle8-ec2-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "ansible_bucket" {
  name = "vle8-ansible-bucket"
  role = aws_iam_role.ssm_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
      Resource = [aws_s3_bucket.ansible_ssm.arn, "${aws_s3_bucket.ansible_ssm.arn}/*"]
    }]
  })
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "vle8-ec2-ssm-profile"
  role = aws_iam_role.ssm_role.name
}

resource "aws_instance" "jenkins" {
  ami                    = data.aws_ssm_parameter.ubuntu_2204.value
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "VLE-8-Jenkins-BlueGreen"
  }
}

# Ansible inventory generated from the instance Terraform just created
resource "local_file" "inventory" {
  filename = "${path.module}/../ansible/inventory.ini"
  content  = <<-EOT
    [jenkins]
    ${aws_instance.jenkins.id}

    [jenkins:vars]
    ansible_connection=community.aws.aws_ssm
    ansible_aws_ssm_region=${var.aws_region}
    ansible_aws_ssm_profile=${var.aws_profile}
    ansible_aws_ssm_bucket_name=${aws_s3_bucket.ansible_ssm.bucket}
    ansible_python_interpreter=/usr/bin/python3
    public_ip=${aws_instance.jenkins.public_ip}
  EOT
}
