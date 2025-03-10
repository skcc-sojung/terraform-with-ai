# variables.tf
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_prefix" {
  description = "Project prefix for resource naming"
  type        = string
  default     = "osj-terraform-with-aq"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "100.0.0.0/16"
}

variable "subnet_config" {
  description = "Configuration for all subnets"
  type = map(object({
    cidr_block        = string
    availability_zone = string
    subnet_type       = string
  }))
  default = {
    pub_a = {
      cidr_block        = "100.0.0.0/24"
      availability_zone = "ap-northeast-2a"
      subnet_type       = "pub"
    }
    pub_c = {
      cidr_block        = "100.0.10.0/24"
      availability_zone = "ap-northeast-2c"
      subnet_type       = "pub"
    }
    prv_ap_a = {
      cidr_block        = "100.0.20.0/24"
      availability_zone = "ap-northeast-2a"
      subnet_type       = "prv-ap"
    }
    prv_ap_c = {
      cidr_block        = "100.0.30.0/24"
      availability_zone = "ap-northeast-2c"
      subnet_type       = "prv-ap"
    }
    prv_db_a = {
      cidr_block        = "100.0.40.0/24"
      availability_zone = "ap-northeast-2a"
      subnet_type       = "prv-db"
    }
    prv_db_c = {
      cidr_block        = "100.0.50.0/24"
      availability_zone = "ap-northeast-2c"
      subnet_type       = "prv-db"
    }
  }
}