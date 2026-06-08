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
        random = { 
            source = "hashicorp/random"
            version = "~> 3.0"
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


##RESOURCES

#S3

resource "random_id" "suffix" {
    byte_length = 4
}

resource "aws_s3_bucket" "terraform_state" {
    bucket = "${var.project_name}-tfstate-${random_id.suffix.hex}"

    lifecycle {
        prevent_destroy = true
    }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
    bucket = aws_s3_bucket.terraform_state.id

    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
    bucket = aws_s3_bucket.terraform_state.id

    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
        }
    }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
    bucket = aws_s3_bucket.terraform_state.id
    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
}

#Dynamo

resource "aws_dynamodb_table" "terraform_state" {
    name = "${var.project_name}-tfstate-locks"
    billing_mode = "PROVISIONED"
    read_capacity = 1
    write_capacity = 1
    hash_key = "LockID"
    attribute {
        name = "LockID"
        type = "S"
    }
}

##Outputs

output "state_bucket_name" {
    value = aws_s3_bucket.terraform_state.bucket
    description = "paste into backend block of modules"
}

output "dynamodb_table_name" {
    value = aws_dynamodb_table.terraform_state.name
    description = "paste into backend of modules"
}

output "region" {
    value = var.region
}