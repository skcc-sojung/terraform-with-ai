# Try 1
### Prompt
> Write a Terraform script to create the following AWS Route Tables:
> 1. Public Route Table
>   - Name tag: osj-terraform-with-{aq | cp}-pub-rt
>   - VPC: osj-terraform-with-{aq | cp}-vpc
> 2. Private Route Table for Application Subnet
>   - Name tag: osj-terraform-with-{aq | cp}-pri-ap-rt
>   - VPC: osj-terraform-with-{aq | cp}-vpc
> 3. Private Route Table for Database Subnet
>    - Name tag: osj-terraform-with-{aq | cp}-pri-db-rt
>    - VPC: osj-terraform-with-{aq | cp}-vpc
>
> Please include the resource definitions for all three route tables, and use the Name tag to label each route table accordingly.


### Response
I'll help you create the Terraform configuration for the three route tables based on your existing VPC configuration. Here's the script: <sup>[1](#footnote_1)</sup>

```hcl
# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "osj-terraform-with-cp-pub-rt"
  }
}

# Private Route Table for Application Subnet
resource "aws_route_table" "private_ap" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "osj-terraform-with-cp-pri-ap-rt"
  }
}

# Private Route Table for Database Subnet
resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "osj-terraform-with-cp-pri-db-rt"
  }
}

# Route Table Associations for Public Subnets
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_c" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.public.id
}

# Route Table Associations for Application Private Subnets
resource "aws_route_table_association" "private_ap_a" {
  subnet_id      = aws_subnet.subnet3.id
  route_table_id = aws_route_table.private_ap.id
}

resource "aws_route_table_association" "private_ap_c" {
  subnet_id      = aws_subnet.subnet4.id
  route_table_id = aws_route_table.private_ap.id
}

# Route Table Associations for Database Private Subnets
resource "aws_route_table_association" "private_db_a" {
  subnet_id      = aws_subnet.subnet5.id
  route_table_id = aws_route_table.private_db.id
}

resource "aws_route_table_association" "private_db_c" {
  subnet_id      = aws_subnet.subnet6.id
  route_table_id = aws_route_table.private_db.id
}
```

Key points about this configuration:

1. Public Route Table:
  - Has a route to the Internet Gateway (0.0.0.0/0)
  - Associated with public subnets (subnet1 and subnet2)

2. Private Application Route Table:
  - Has a route through the NAT Gateway for internet access
  - Associated with application private subnets (subnet3 and subnet4)

3. Private Database Route Table:
  - No internet access routes defined (isolated)
  - Associated with database private subnets (subnet5 and subnet6)

4. Route Table Associations:
  - Each subnet is explicitly associated with its corresponding route table
  - Associations are named to clearly indicate which subnet they connect

The configuration:
 - Uses your existing VPC, Internet Gateway, and NAT Gateway
 - Creates appropriate routing for each subnet tier
 - Follows AWS best practices for network isolation
 - Maintains consistent naming conventions

Remember that:
 - Public subnets can access the internet directly via the Internet Gateway
 - Application private subnets can access the internet via the NAT Gateway
 - Database private subnets have no internet access for security


#### Sources
<a name="footnote_1">[1]</a>[Amazon EC2 examples using AWS CLI - AWS SDK Code Examples](docs.aws.amazon.comcode-librarylatestcli_2_ec2_code_examples.html)

<br/>

## 스크립트 개선
### Prompt
> Refactor the Terraform code to reduce duplication by using variables defined in a variables.tf file.
Make the code more reusable and cleaner by referencing variables such as VPC ID and name prefixes, instead of hardcoding values.

### Response
I'll help you refactor the code to make it more maintainable and reusable. Here's the improved version:

1. First, let's create/update the `variables.tf`:

```hcl
# variables.tf
variable "project_prefix" {
  description = "Prefix for resource naming"
  type        = string
  default     = "osj-terraform-with-aq"
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
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
    public = {
      type = "public"
      routes = [{
        cidr_block  = "0.0.0.0/0"
        gateway_key = "igw"
      }]
    }
    private_ap = {
      type = "private_ap"
      routes = [{
        cidr_block  = "0.0.0.0/0"
        gateway_key = "nat"
      }]
    }
    private_db = {
      type    = "private_db"
      routes  = []
    }
  }
}

variable "subnet_associations" {
  description = "Map of subnet IDs to route table types"
  type = map(object({
    subnet_id = string
    rt_type   = string
  }))
}

```

2. Update the `main.tf`:
```
# main.tf
locals {
  gateway_ids = {
    igw = aws_internet_gateway.main.id
    nat = aws_nat_gateway.main.id
  }
}

# Create route tables
resource "aws_route_table" "this" {
  for_each = var.route_tables
  vpc_id   = aws_vpc.main.id

  tags = {
    Name = "${var.project_prefix}-${each.key}-rt"
  }
}

# Create routes
resource "aws_route" "this" {
  for_each = {
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

  route_table_id         = aws_route_table.this[each.value.rt_key].id
  destination_cidr_block = each.value.cidr_block
  gateway_id            = try(local.gateway_ids[each.value.gateway_key], null)
  nat_gateway_id        = try(local.gateway_ids[each.value.gateway_key], null)
}

# Create route table associations
resource "aws_route_table_association" "this" {
  for_each = var.subnet_associations

  subnet_id      = each.value.subnet_id
  route_table_id = aws_route_table.this[each.value.rt_type].id
}
```

3. Create a `terraform.tfvars` file:
```
# terraform.tfvars
project_prefix = "osj-terraform-with-aq"

subnet_associations = {
  "public_a" = {
    subnet_id = "subnet-xxxxx1"  # Replace with your subnet IDs
    rt_type   = "public"
  }
  "public_c" = {
    subnet_id = "subnet-xxxxx2"
    rt_type   = "public"
  }
  "private_ap_a" = {
    subnet_id = "subnet-xxxxx3"
    rt_type   = "private_ap"
  }
  "private_ap_c" = {
    subnet_id = "subnet-xxxxx4"
    rt_type   = "private_ap"
  }
  "private_db_a" = {
    subnet_id = "subnet-xxxxx5"
    rt_type   = "private_db"
  }
  "private_db_c" = {
    subnet_id = "subnet-xxxxx6"
    rt_type   = "private_db"
  }
}
```

Key improvements in this refactored version:
1. Dynamic Resource Creation :
   - Uses for_each to create multiple route tables
   - Dynamically creates routes based on configuration
   - Handles route table associations flexibly

2. Reduced Duplication :
   - Common values are defined once in variables
   - Resource naming follows a consistent pattern
   - Route configurations are templated

3. Improved Maintainability :
   - All configurations are in variables
   - Easy to add or modify route tables
   - Clear separation of configuration from implementation

4. Better Organization :
   - Variables are properly typed and documented
   - Uses locals for computed values
   - Configuration is environment-independent

To use this configuration:
1. Update the subnet IDs in terraform.tfvars with your actual subnet IDs
2. Adjust the project_prefix if needed
3. Run Terraform commands:

```hcl
terraform init
terraform plan
terraform apply
```

This refactored version is:
- More maintainable
- More reusable
- Less prone to errors
- Easier to modify
- Following Terraform best practices

Remember to replace the subnet IDs with your actual subnet IDs before applying the configuration.