variable "region" {
  default = "us-east-2"
}

variable "ami_id" {
  description = "AMI ID created by Packer"
}

variable "instance_type" {
  default = "c7i-flex.large"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  default = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "azs" {
  default = ["us-east-2a", "us-east-2b"]
}
variable "key_name" {
  description = "Name of the SSH key pair"
}