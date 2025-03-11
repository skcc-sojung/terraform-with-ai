# Try 1
### Prompt
> Write a Terraform script to associate subnets with their respective AWS Route Tables.
> 
> * Associate the `osj-terraform-with-{aq | cp}-pub-rt` route table with the following subnets:
>   - osj-terraform-with-{aq | cp}-pub-a
>   - osj-terraform-with-{aq | cp}-pub-c
>
> * Associate the `osj-terraform-with-{aq | cp}-prv-ap-rt` route table with the following subnets:
>   - osj-terraform-with-{aq | cp}-prv-ap-a
>   - osj-terraform-with-{aq | cp}-prv-ap-c
>
> * Associate the `osj-terraform-with-{aq | cp}-prv-db-rt` route table with the following subnets:
>   - osj-terraform-with-{aq | cp}-prv-db-a
>   - osj-terraform-with-{aq | cp}-prv-db-c
>
> Use the `aws_route_table_association` resource for each association. If possible, make the code reusable by referencing variables from `variables.tf.`

<br/>


### Response
I'll help you create a Terraform script for route table associations using your existing variables and making it reusable. Based on your variables.tf file, here's the implementation:

```hcl
# Route table associations using dynamic configuration
resource "aws_route_table_association" "subnet_associations" {
  for_each = var.subnet_config

  subnet_id = aws_subnet.subnets[each.key].id
  route_table_id = aws_route_table.this[
    lookup({
      "pub"    = "pub"
      "prv-ap" = "prv_ap"
      "prv-db" = "prv_db"
    }, each.value.subnet_type)
  ].id
}

# Alternative approach using locals for better readability
locals {
  subnet_route_table_map = {
    for name, config in var.subnet_config : name => {
      subnet_id = aws_subnet.subnets[name].id
      route_table_type = lookup({
        "pub"    = "pub"
        "prv-ap" = "prv_ap"
        "prv-db" = "prv_db"
      }, config.subnet_type)
    }
  }
}

resource "aws_route_table_association" "subnets" {
  for_each = local.subnet_route_table_map

  subnet_id      = each.value.subnet_id
  route_table_id = aws_route_table.this[each.value.route_table_type].id
}
```

This code:
1. Uses your existing subnet_config variable structure

2. Automatically associates subnets with their corresponding route tables based on subnet type <sup>[1](#footnote_1)</sup>

3. Uses a lookup map to match subnet types to route table names

4. Creates associations for all subnets defined in your variables

The code will automatically:
  - Associate public subnets with the public route table <sup>[2](#footnote_2)</sup>
  - Associate private application subnets with the private application route table
  - Associate private database subnets with the private database route table

Your existing variables.tf already has the necessary structure with:
```hcl
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
```

Benefits of this approach:
1. DRY (Don't Repeat Yourself) - no repetitive code
2. Maintainable - all configurations in one place
3. Scalable - easily add new subnets by updating variables
4. Consistent - uses the same naming convention throughout
5. Error-resistant - uses variable references instead of hardcoded values

The associations will be created automatically based on the subnet type defined in your variables, making the code more maintainable and less prone to errors.

#### Sources
<a name="footnote_1">[1]</a>[Use AssociateRouteTable with a CLI - Amazon Elastic Compute Cloud](
docs.aws.amazon.comec2latestexample_ec2_AssociateRouteTable_section.html)

<a name="footnote_2">[2]</a> [Use AssociateRouteTable with a CLI - AWS SDK Code Examples](docs.aws.amazon.comcode-librarylatestec2_example_ec2_AssociateRouteTable_section.html)

<br/>
