###################################################################
# Variables with no defaults
###################################################################

variable "app_type" {
  description = "Specify the private name, or use `sys` for internal use."
}

variable "content_type" {
  description = "An arbitrary description of the type of content that the resource will deal with, for example logs, etc."
}

variable "enable_nat_gateway" {
  description = "Specify wheter to enable the NAT gateway service: true | false"
}

variable "environment" {
  description = "Specify the environment. Can be one of `dev`, `stg`, `uat`, `oat`, `prd`."
}

variable "tenant_id" {
  description = "Specify a `tenant_id`, or `000000` (six zeros) for internal use."
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC."
}

###################################################################
# Variables with defaults
###################################################################

variable "private_subnets" {
  type        = "list"
  description = "This is a list of app subnets inside the VPC."
  default     = []
}

variable "data_subnets" {
  type        = "list"
  description = "This is a list of data subnets"
  default     = []
}

variable "public_subnets" {
  type        = "list"
  description = "This is a list of public subnets inside the VPC."
  default     = []
}

variable "tags" {
  type        = "map"
  description = "Specify a map of tags."
  default     = {}
}