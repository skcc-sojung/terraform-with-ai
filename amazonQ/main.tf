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

locals {
  # Map gateway types to their resource IDs
  gateway_ids = {
    igw = aws_internet_gateway.main.id
    nat = aws_nat_gateway.main.id
  }

  # Create a flattened map of routes for easier iteration
  route_configurations = {
    for pair in flatten([
      for rt_key, rt in var.route_tables : [
        for route in rt.routes : {
          rt_key      = rt_key
          cidr_block  = route.cidr_block
          gateway_key = route.gateway_key
        }
      ]
    ]) : "${pair.rt_key}-${pair.cidr_block}" => pair
  }
}

# Create route tables
resource "aws_route_table" "this" {
  for_each = var.route_tables
  vpc_id   = aws_vpc.main.id

  tags = {
    Name = "${var.project_prefix}-${replace(each.key, "_", "-")}-rt"
  }
}

# Route table associations using dynamic configuration
resource "aws_route_table_association" "subnet_associations" {
  for_each = var.subnet_config

  subnet_id = aws_subnet.subnets[each.key].id
  route_table_id = aws_route_table.this[
    lookup({
      "pub"    = "pub"
      "prv-ap" = "prv-ap"
      "prv-db" = "prv-db"
    }, each.value.subnet_type)
  ].id
}

# Create routes using the flattened configuration
resource "aws_route" "routes" {
  for_each = local.route_configurations

  route_table_id         = aws_route_table.this[each.value.rt_key].id
  destination_cidr_block = each.value.cidr_block

  # Conditionally set the gateway_id or nat_gateway_id
  gateway_id     = each.value.gateway_key == "igw" ? local.gateway_ids["igw"] : null
  nat_gateway_id = each.value.gateway_key == "nat" ? local.gateway_ids["nat"] : null

  depends_on = [
    aws_route_table.this,
    aws_internet_gateway.main,
    aws_nat_gateway.main
  ]
}