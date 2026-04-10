terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.39.0"
    }
    linode = {
      source  = "linode/linode"
      version = "3.11.0"
    }
  }
}