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
Here is the Terraform script to add routes to the specified AWS Route Tables:

```hcl
/* ... */

resource "aws_route" "public_rt_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route" "private_ap_rt_route" {
  route_table_id         = aws_route_table.private_ap_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}
```

<br/>

`variables.tf`
```hcl
variable "env" {
  description = "Environment identifier (e.g., aq or cp)"
  type        = string
}

variable "existing_eip_public_ip" {
  description = "Public IP of the existing Elastic IP"
  type        = string
}
```

This script adds the necessary routes to the public and private application route tables. The `env` variable is used to make the script reusable for different environments (e.g., `aq` or `cp`). Replace `YOUR_EXISTING_EIP_PUBLIC_IP` with the actual public IP address of the existing Elastic IP.