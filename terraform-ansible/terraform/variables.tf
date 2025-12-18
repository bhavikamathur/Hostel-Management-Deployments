
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "hostel-profile"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDRs for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "key_name" {
  description = "Existing EC2 Key Pair name"
  type        = string
  default     = "hostel-terraform-ansible"
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to SSH to web/DB instances"
  type        = string
  default     = "54.226.111.100/32" # your provided IP
}

variable "web_instance_type" {
  type    = string
  default = "t2.medium"
}

variable "db_instance_type" {
  type    = string
  default = "t3.small"
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default = {
    Project = "hostel-2tier"
    Owner   = "Rohit"
    Env     = "dev"
  }
}

