terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.4.0"
}

provider "aws" {
  region = var.region
  access_key = "AKIA3PYX5SHDVSP4ZE6O"
  secret_key = "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"
}