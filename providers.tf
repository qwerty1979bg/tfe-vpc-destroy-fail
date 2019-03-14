###################################################################
# Provider Configuration
###################################################################

data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

provider "aws" {
  region = "us-east-1"
}
