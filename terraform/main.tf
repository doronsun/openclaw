terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# -------------------------------------------------------
# Security Group — חומת האש ל-Kubernetes
# -------------------------------------------------------
resource "aws_security_group" "open_claw_sg" {
  name        = "open-claw-sg"
  description = "Security Group for Open-Claw K8s Cluster"
  vpc_id      = var.vpc_id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH"
  }

  # Kubernetes API Server
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Kubernetes API Server"
  }

  # etcd — פנימי בלבד
  ingress {
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
    description = "etcd"
  }

  # Kubelet API
  ingress {
    from_port   = 10250
    to_port     = 10252
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
    description = "Kubelet API"
  }

  # NodePort Services
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "NodePort Services"
  }

  # תקשורת פנימית חופשית בין הנודים
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["172.31.0.0/16"]
    description = "Internal VPC traffic"
  }

  # תעבורה יוצאת — פתוח לכל
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name    = "open-claw-sg"
    Project = "open-claw"
  }
}

# -------------------------------------------------------
# Data Source — נמשוך את ה-AMI העדכני של Ubuntu 22.04
# -------------------------------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# -------------------------------------------------------
# Master Node
# -------------------------------------------------------
resource "aws_instance" "master" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.master_instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.open_claw_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name    = "open-claw-master"
    Role    = "master"
    Project = "open-claw"
  }
}

# -------------------------------------------------------
# Worker Node
# -------------------------------------------------------
resource "aws_instance" "worker" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.worker_instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.open_claw_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name    = "open-claw-worker"
    Role    = "worker"
    Project = "open-claw"
  }
}