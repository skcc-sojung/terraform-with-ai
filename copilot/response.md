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
Here is a Terraform script to modify the inbound rules of a Security Group with the specified configuration:

`main.tf`
```hcl
provider "aws" {
  region = "ap-northeast-2"
}

variable "env" {
  description = "Environment identifier (e.g., aq or cp)"
  type        = string
}

resource "aws_security_group" "ec2_sg" {
  name        = "osj-terraform-with-${var.env}-ec2-sg"
  description = "Security group for EC2 instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "osj-terraform-with-${var.env}-pub-a-CIDR"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["100.0.0.0/24"]
  }

  ingress {
    description = "osj-terraform-with-${var.env}-pub-c-CIDR"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["100.0.10.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "osj-terraform-with-${var.env}-ec2-sg"
  }
}

resource "aws_vpc" "main" {
  cidr_block           = "100.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"

  tags = {
    Name = "osj-terraform-with-${var.env}-vpc"
  }
}
```

`variables.tf`
```hcl
variable "env" {
  description = "Environment identifier (e.g., aq or cp)"
  type        = string
}
```

Explanation
1. Provider Configuration: Specifies the AWS region.
2. Variables: Defines the env variable for environment identification.
3. Security Group: Creates a security group with the name osj-terraform-with-${var.env}-ec2-sg and adds the specified inbound rules:
    * Rule 1: Allows TCP traffic on port 80 from the CIDR block 100.0.0.0/24 with a description.
    * Rule 2: Allows TCP traffic on port 80 from the CIDR block 100.0.10.0/24 with a description.
4. VPC: Assumes the VPC already exists but includes its definition for completeness.

This script sets up the security group with the specified inbound rules and descriptions. Adjust the env variable as needed for different environments (e.g., aq or cp).
