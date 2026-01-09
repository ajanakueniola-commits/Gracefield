# variable "region" {
#   default = "us-east-2"
# }

# variable "packer_ami_name_pattern" {
#   description = "If set, Terraform will look up an AMI by this name pattern (use % wildcard), otherwise falls back to Amazon Linux 2 image pattern. Example: 'myapp-*'"
#   type        = string
#   default     = ""
# }

# variable "packer_ami_owner" {
#   description = "Owner to use when looking up the packer AMI. Use 'self' for your account. If empty, defaults to 'amazon' for regular Amazon Linux lookup."
#   type        = string
#   default     = ""
# }
# variable "ami_id" {
#   description = "AMI ID to use for EC2 instances"
# }

# variable "instance_type" {
#   default = "c7i-flex.large"
# }

# variable "vpc_cidr" {
#   default = "10.0.0.0/16"
# }

# variable "public_subnets" {
#   default = ["10.0.1.0/24", "10.0.2.0/24"]
# }

# variable "private_subnets" {
#   default = ["10.0.11.0/24", "10.0.12.0/24"]
# }

# variable "azs" {
#   default = ["us-east-2a", "us-east-2b"]
# }
# variable "key_name" {
#   description = "Name of the SSH key pair"
# }
# variable "db_allocated_storage" {
#   default = 20
# }

variable "region" {
  description = "AWS region"
  default     = "us-east-2"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "List of public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "List of private subnet CIDRs"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "azs" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b"]
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "c7i-flex.large"
}

variable "packer_ami_name_pattern" {
  description = "AMI name pattern if using a Packer-built AMI"
  default     = ""
}

variable "packer_ami_owner" {
  description = "AMI owner ID if using Packer-built AMI"
  default     = ""
}

variable "ami_id" {
  description = "Optional explicit AMI ID to use"
  default     = ""
}
