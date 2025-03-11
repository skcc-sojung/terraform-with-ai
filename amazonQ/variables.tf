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

variable "existing_eip_id" {
  description = "Allocation ID of existing Elastic IP to use for NAT Gateway"
  type        = string
}

variable "existing_eip_tags" {
  description = "Tags to find existing Elastic IP"
  type        = map(string)
}

variable "route_tables" {
  description = "Configuration for route tables"
  type = map(object({
    type           = string        # "public", "private_ap", or "private_db"
    routes         = list(object({
      cidr_block     = string
      gateway_key    = string      # "igw" or "nat"
    }))
  }))
  default = {
    pub = {
      type = "pub"
      routes = [{
        cidr_block  = "0.0.0.0/0"
        gateway_key = "igw"
      }]
    }
    prv-ap = {
      type = "prv-ap"
      routes = [{
        cidr_block  = "0.0.0.0/0"
        gateway_key = "nat"
      }]
    }
    prv-db = {
      type    = "prv-db"
      routes  = []
    }
  }
}
