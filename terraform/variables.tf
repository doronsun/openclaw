variable "region" {
  description = "AWS Region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID"
  type        = string
}

variable "key_name" {
  description = "Key Pair Name"
  type        = string
}

variable "master_instance_type" {
  description = "Instance type for master node"
  type        = string
  default     = "t3.small"
}

variable "worker_instance_type" {
  description = "Instance type for worker node"
  type        = string
  default     = "t2.micro"
}