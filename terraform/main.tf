provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket         = "time-to-eat-terraform-state-bucket"
    key            = "terraform.tfstate"
  }
}