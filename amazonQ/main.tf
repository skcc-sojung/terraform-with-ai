# main.tf
resource "aws_vpc" "main" {
  cidr_block           = "100.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "osj-terraform-with-aq-vpc"
  }
}