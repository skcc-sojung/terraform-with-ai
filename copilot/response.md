# Try 1
### Prompt
Write a Terraform script that creates an AWS Security Group and an Application Load Balancer with the following configuration:

* Security Group Configuration:
  * Name: osj-terraform-with-{aq | cp}-alb-sg
  * Description: "security group for load balancer"
  * VPC: osj-terraform-with-{aq | cp}-vpc
  * Inbound Rule:
    - Type: Custom TCP
    - Protocol: TCP
    - Port Range: 80
    - Source: 0.0.0.0/0
  * Outbound Rule:
    - Type: All Traffic
    - Protocol: All
    - Port Range: All
    - Destination: 0.0.0.0/0

* Application Load Balancer Configuration:
  * Name: osj-terraform-with-{aq | cp}-alb
  * Scheme: internet-facing
  * IP address type: IPv4
  * VPC: osj-terraform-with-{aq | cp}-vpc
  * Subnet mappings:
    - ap-northeast-2a: osj-terraform-with-{aq | cp}-pub-a
    - ap-northeast-2c: osj-terraform-with-{aq | cp}-pub-c
  * Security Group: osj-terraform-with-{aq | cp}-alb-sg
  * Listener:
    - Protocol: HTTP
    - Port: 80
    - Default action: forward to target group osj-terraform-with-{aq | cp}-tg


### Response
Here is the Terraform script to create an AWS Security Group and an Application Load Balancer with the specified configuration:

`main.tf`
```hcl
provider "aws" {
  region = "ap-northeast-2"
}

variable "env" {
  description = "Environment identifier (e.g., aq or cp)"
  type        = string
}

resource "aws_security_group" "alb_sg" {
  name        = "osj-terraform-with-${var.env}-alb-sg"
  description = "security group for load balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "osj-terraform-with-${var.env}-alb-sg"
  }
}

resource "aws_lb" "alb" {
  name               = "osj-terraform-with-${var.env}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  tags = {
    Name = "osj-terraform-with-${var.env}-alb"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
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

resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "100.0.0.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "osj-terraform-with-${var.env}-pub-a"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "100.0.10.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "osj-terraform-with-${var.env}-pub-c"
  }
}

resource "aws_lb_target_group" "target_group" {
  name     = "osj-terraform-with-${var.env}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  target_type = "instance"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "osj-terraform-with-${var.env}-target-group"
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
3. Security Group: Creates a security group for the load balancer with the specified inbound and outbound rules.
4. Application Load Balancer: Creates an internet-facing Application Load Balancer with the specified configuration, including subnet mappings and security group.
5. Listener: Creates an HTTP listener for the load balancer that forwards traffic to the specified target group.
6. VPC and Subnets: Defines the VPC and subnets.
7. Target Group: Creates a target group for the load balancer.

Replace the env variable value as needed for different environments (e.g., aq or cp). This script sets up the security group, load balancer, listener, VPC, subnets, and target group as specified.