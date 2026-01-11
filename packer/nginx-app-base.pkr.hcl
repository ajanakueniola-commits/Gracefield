packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.2.0"
    }
  }
}

variable "region" {
  default = "us-east-2"
}

source "amazon-ebs" "base" {
  region        = var.region
  instance_type = "c7i-flex.large"
  ssh_username  = "ec2-user"
  ami_name      = "grace-base-ami-{{timestamp}}"

  source_ami_filter {
    filters = {
      name                = "amzn2-ami-hvm-*-x86_64-gp2"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["amazon"]
    most_recent = true
  }
}

build {
  name    = "base-ami-build"
  sources = ["source.amazon-ebs.base"]

  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo yum install python3 -y",
      "sudo yum install git -y"
    ]
  }

  post-processor "manifest" {
    output = "manifest.json"
  }
}
