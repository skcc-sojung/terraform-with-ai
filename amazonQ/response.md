# Try 1
### Prompt
> Write a Terraform script to add routes to specific AWS Route Tables.
> 
> * For the route table osj-terraform-with-{aq | cp}-pub-rt, add a route:
>   - Destination CIDR block: 0.0.0.0/0
>   - Target: Internet Gateway (osj-terraform-with-{aq | cp}-igw)
> * For the route table osj-terraform-with-{aq | cp}-prv-ap-rt, add a route:
>   - Destination CIDR block: 0.0.0.0/0
>   - Target: NAT Gateway (osj-terraform-with-{aq | cp}-nat)
> * For the route table osj-terraform-with-{aq | cp}-prv-db-rt, no routing configuration is needed.
>
> Use the aws_route resource in Terraform and consider using variables for dynamic referencing where appropriate.

<br/>

### Response
I'll help you create a Terraform script to add routes to your route tables using your existing variable structure. Here's the implementation:

```hcl
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

# Create routes using the flattened configuration
resource "aws_route" "routes" {
  for_each = local.route_configurations

  route_table_id         = aws_route_table.this[each.value.rt_key].id
  destination_cidr_block = each.value.cidr_block

  # Dynamically set the appropriate gateway based on the gateway_key
  dynamic "gateway" {
    for_each = each.value.gateway_key == "igw" ? [1] : []
    content {
      gateway_id = local.gateway_ids["igw"]
    }
  }

  dynamic "gateway" {
    for_each = each.value.gateway_key == "nat" ? [1] : []
    content {
      nat_gateway_id = local.gateway_ids["nat"]
    }
  }

  depends_on = [
    aws_route_table.this,
    aws_internet_gateway.main,
    aws_nat_gateway.main
  ]
}
```
And here's how to update your variables.tf to support this configuration:

```hcl
# variables.tf
variable "route_tables" {
  description = "Configuration for route tables"
  type = map(object({
    type    = string        # "pub", "prv-ap", or "prv-db"
    routes  = list(object({
      cidr_block  = string
      gateway_key = string  # "igw" or "nat"
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
    "prv-ap" = {
      type = "prv-ap"
      routes = [{
        cidr_block  = "0.0.0.0/0"
        gateway_key = "nat"
      }]
    }
    "prv-db" = {
      type = "prv-db"
      routes = []  # No routes needed for database subnet
    }
  }
}
```

You can also use `terraform.tfvars` to override the default values:
```hcl
# terraform.tfvars
route_tables = {
  pub = {
    type = "pub"
    routes = [{
      cidr_block  = "0.0.0.0/0"
      gateway_key = "igw"
    }]
  }
  "prv-ap" = {
    type = "prv-ap"
    routes = [{
      cidr_block  = "0.0.0.0/0"
      gateway_key = "nat"
    }]
  }
  "prv-db" = {
    type = "prv-db"
    routes = []
  }
}
```

This configuration:
1. Creates routes based on the configuration in variables
2. Automatically associates routes with the correct gateways
3. Handles both Internet Gateway and NAT Gateway routes
4. Skips route creation for the database route table
5. Uses dynamic blocks for gateway assignment
6. Includes proper dependencies

Key features:
1. Dynamic Route Creation :
  - Routes are created based on the configuration in variables
  - Each route table can have multiple routes
  - Empty route lists are handled properly
2. Gateway Assignment :
  - Uses the correct gateway type based on the configuration
  - Supports both Internet Gateway and NAT Gateway
  - Handles dependencies properly
3. Maintainability :
  - All configuration is in variables
  - Easy to modify routes
  - Clear separation of concerns
4. Error Prevention :
  - Includes necessary dependencies
  - Uses proper resource references
  - Validates configuration through variable types

The script will:
* Add the internet route (0.0.0.0/0) via IGW for the public route table
* Add the internet route (0.0.0.0/0) via NAT for the private application route table
* Skip route creation for the private database route table

Remember to ensure that:
1. Your VPC, Internet Gateway, and NAT Gateway are properly configured
2. The route table associations are set up correctly
3. The necessary permissions are in place

## Troubleshooting
`aws_route`에서 지원하지 않는 dynamic 블록을 스크립트에 생성하여 에러 발생

### Prompt
* 에러 삽입
```
Error: Unsupported block type
│
│ on main.tf line 102, in resource "aws_route" "routes":
│ 102: dynamic "gateway" {
│
│ Blocks of type "gateway" are not expected here.
╵
╷
│ Error: Unsupported block type
│
│ on main.tf line 109, in resource "aws_route" "routes":
│ 109: dynamic "gateway" {
│
│ Blocks of type "gateway" are not expected here.
```

### Response
I apologize for the error. The `aws_route` resource doesn't use dynamic blocks for gateway configuration. Here's the corrected version:

```hcl
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
```

Key changes:
1. Removed the dynamic blocks
2. Used conditional expressions to set the appropriate gateway
3. Set unused gateway values to null

This corrected version will:
 - Create routes for public subnets using the Internet Gateway
 - Create routes for private application subnets using the NAT Gateway
 - Skip route creation for database subnets
 - Properly handle the gateway assignments

The rest of your configuration (variables and locals) remains the same.
