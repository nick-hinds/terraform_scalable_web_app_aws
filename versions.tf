terraform {
  required_version = ">= 1.14.3"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.85.0"  # Latest as of December 2024
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.3"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.6"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12.1"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4.5"
    }
  }
  
  # Backend configuration for state management
  backend "s3" {
    # These will be configured via backend config file or CLI flags
    # bucket         = "terraform-state-bucket"
    # key            = "infrastructure/terraform.tfstate"
    # region         = "us-east-1"
    # encrypt        = true
    # dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = local.common_tags
  }
  
  # Terraform 1.14+ feature: skip_metadata_api_check
  skip_metadata_api_check     = false
  skip_region_validation      = false
  skip_credentials_validation = false
}

provider "random" {}
provider "tls" {}
provider "time" {}
provider "http" {}