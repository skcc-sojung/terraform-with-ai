# main.tf
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_prefix}-vpc"
  }
}

resource "aws_subnet" "subnets" {
  for_each = var.subnet_config

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone

  tags = {
    Name = "${var.project_prefix}-${each.value.subnet_type}-${substr(each.value.availability_zone, -1, 1)}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "osj-terraform-with-aq-igw"
  }
}

data "aws_eip" "existing_eip" {
  id = var.existing_eip_id
}

# Create NAT Gateway
resource "aws_nat_gateway" "main" {
  allocation_id = data.aws_eip.existing_eip.id
  subnet_id = aws_subnet.subnets["pub_a"].id

  tags = {
    Name = "${var.project_prefix}-nat"
  }

  depends_on = [aws_internet_gateway.main]
}

