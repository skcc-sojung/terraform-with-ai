# Try 1
### Prompt
> Generate a Terraform script to modify the inbound rules  of a Security Group.
> 
> * Security Group Name: osj-terraform-with-{aq | cp}-ec2-sg
> * Inbound Rules:
>   * Rule 1:
>    - Type: Custom TCP
>    - Protocol: TCP
>    - Port Range: 80
>    - Source: 100.0.0.0/24
>    - Description: osj-terraform-with-{aq | cp}-pub-a-CIDR
>  * Rule 2:
>    - Type: Custom TCP
>    - Protocol: TCP
>    - Port Range: 80
>    - Source: 100.0.10.0/24
>    - Description: osj-terraform-with-{aq | cp}-pub-c-CIDR


### Response
Here's a Terraform script to modify the inbound rules of an existing security group:
```hcl
# Variables
variable "env" {
  description = "Environment identifier (aq or cp)"
  type        = string
}

# Data source to fetch existing security group
data "aws_security_group" "existing" {
  tags = {
    Name = "osj-terraform-with-${var.env}-ec2-sg"
  }
}

# Security group rules
resource "aws_security_group_rule" "inbound_pub_a" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["100.0.0.0/24"]
  security_group_id = data.aws_security_group.existing.id
  description       = "osj-terraform-with-${var.env}-pub-a-CIDR"
}

resource "aws_security_group_rule" "inbound_pub_c" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["100.0.10.0/24"]
  security_group_id = data.aws_security_group.existing.id
  description       = "osj-terraform-with-${var.env}-pub-c-CIDR"
}
```

Alternative approach using a more maintainable configuration with locals:
```hcl
# Variables
variable "env" {
  description = "Environment identifier (aq or cp)"
  type        = string
}

# Local variables for rule configuration
locals {
  security_group_rules = {
    pub_a = {
      type        = "ingress"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["100.0.0.0/24"]
      description = "osj-terraform-with-${var.env}-pub-a-CIDR"
    }
    pub_c = {
      type        = "ingress"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["100.0.10.0/24"]
      description = "osj-terraform-with-${var.env}-pub-c-CIDR"
    }
  }
}

# Data source to fetch existing security group
data "aws_security_group" "existing" {
  tags = {
    Name = "osj-terraform-with-${var.env}-ec2-sg"
  }
}

# Security group rules using for_each
resource "aws_security_group_rule" "inbound_rules" {
  for_each = local.security_group_rules

  type              = each.value.type
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  security_group_id = data.aws_security_group.existing.id
  description       = each.value.description
}
```

To apply this configuration:
1. Save the code in a .tf file (e.g., security_group_rules.tf)
2. Initialize Terraform:
```hcl
terraform init
```

3. Apply the configuration with your environment variable:
```hcl
terraform apply -var="env=aq"
```

Key features of this configuration:
1. Uses a data source to fetch the existing security group
2. Creates individual security group rules using aws_security_group_rule
3. The second approach uses for_each to create rules from a map of configurations
4. Makes the configuration reusable across different environments using the env variable
5. Includes descriptions for better documentation of the rules

Benefits of using the second approach with for_each:
1. More maintainable - all rules are defined in one place
2. Easier to add/remove rules - just modify the local variable
3. Reduces code duplication
4. Each rule is tracked individually in the Terraform state
5. Makes it easier to make bulk changes to rule properties

Remember that:
* The security group must exist before applying these rules
* Each rule must have a unique combination of type, protocol, and port range
* You may need to remove any existing rules that conflict with these new ones
* The security group ID will be automatically fetched based on the tag name

