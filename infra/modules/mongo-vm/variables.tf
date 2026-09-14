variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "ssh_allowed_cidr" {
  type = string
}

variable "k8s_subnet_cidrs" {
  type = list(string)
}

variable "key_pair_name" {
  type = string
}

variable "instance_profile_name" {
  type = string
}

variable "instance_type" {
  description = "EC2 instance type for the Mongo VM. t3.small is a comfortable/cheap default; t3.micro is free-tier eligible on a new account but can be tight for MongoDB's default WiredTiger cache."
  type        = string
  default     = "t3.small"
}
