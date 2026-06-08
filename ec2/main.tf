terraform {
    backend "s3" {
  bucket         = "zen-infra-project-tfstate-bde3a954"
  key            = "backend/terraform.tfstate"
  region         = "us-east-1"
  dynamodb_table = "zen-infra-project-tfstate-locks"
  encrypt        = true
}
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}

variable "region" {
    description = "Set region"
    type = string
    default = "us-east-1"
}

variable "project_name" {
    description = "Namespaces all resources"
    type = string
    default = "zen-infra-project"
}

provider "aws" {
    region = var.region
}

##VPC

variable "vpc_id" {
    description = "VPC_ID"
    type = string
}

variable "subnet_id" {
    description = "Public Subnet ID"
    type = string
}

##SECURITY GROUP

resource "aws_security_group" "ec2" {
    name = "${var.project_name}-ec2-sg"
    vpc_id = var.vpc_id

    ingress {
        from_port = 22
        to_port = 22
       protocol = "tcp"
       cidr_blocks = ["0.0.0.0/0"]
    }
      ingress {
        from_port = 80
        to_port = 80
       protocol = "tcp"
       cidr_blocks = ["0.0.0.0/0"]
    }
      ingress {
        from_port = 443
        to_port = 443
       protocol = "tcp"
       cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.project_name}-ec2sg"
    }
}

##EC2

resource "aws_instance" "main" {
    ami = "ami-0c02fb55956c7d316"
    instance_type = "t3.micro"
    subnet_id = var.subnet_id
    vpc_security_group_ids = [aws_security_group.ec2.id]
    associate_public_ip_address = true

    tags = {
        Name = "${var.project_name}-server"
    }
}

##OUTPUTS

output "public_ip" {
    value = aws_instance.main.public_ip
    description = "Public IP of the EC2"
}

output "instance_id" {
    value = aws_instance.main.id
    description = "EC2 ID"
}