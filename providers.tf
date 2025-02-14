terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    
  }

  backend "s3" {
    bucket         = "reverse-ip-app-terraform-state-bucket"
    key            = "reverse-ip-app/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "reverse-ip-app-terraform-lock-table"
    encrypt        = true
  }
}

provider "aws" {
  region = local.config["aws_region"]
  profile = local.config["aws_profile"]
}
