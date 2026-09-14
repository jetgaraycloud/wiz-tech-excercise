variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix used to name/tag all resources"
  type        = string
  default     = "wiz-exercise"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (Mongo VM lives here)"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (EKS Fargate lives here)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "availability_zones" {
  description = "AZs to spread subnets across (must match subnet CIDR list lengths)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to SSH into the Mongo VM. Intentionally 0.0.0.0/0 per exercise requirements."
  type        = string
  default     = "0.0.0.0/0"
}

variable "key_pair_name" {
  description = "Existing EC2 key pair name for SSH access to the Mongo VM"
  type        = string
}

variable "eks_cluster_version" {
  description = "Kubernetes version for the EKS control plane"
  type        = string
  default     = "1.32"
}

variable "mongo_vm_instance_type" {
  description = "EC2 instance type for the Mongo VM. t3.small (default) is a cheap, comfortable fit for MongoDB. Use t3.micro to stay inside a new account's free tier, but watch for memory pressure."
  type        = string
  default     = "t3.small"
}
