# Try 1
### Prompt
> Write a Terraform script to create an AWS Target Group with the following configuration:
> * Target type: instance
> * Target group name: osj-terraform-with-{aq | cp}-target-group
> * Protocol and port: HTTP:80
> * VPC: osj-terraform-with-{aq | cp}-vpc
> * Register the following EC2 instances as targets (assumed to be created beforehand and their instance IDs available):
>   - osj-terraform-with-{aq | cp}-app-1
>   - osj-terraform-with-{aq | cp}-app-2


### Response
Here is a Terraform script to create an AWS Target Group with the specified configuration and register the given EC2 instances as targets:

`main.tf`
```hcl
provider "aws" {
  region = "ap-northeast-2"
}

variable "env" {
  description = "Environment identifier (e.g., aq or cp)"
  type        = string
}

variable "app_instance_ids" {
  description = "List of EC2 instance IDs to register as targets"
  type        = list(string)
}

resource "aws_lb_target_group" "target_group" {
  name     = "osj-terraform-with-${var.env}-target-group"
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

resource "aws_lb_target_group_attachment" "app1" {
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id        = element(var.app_instance_ids, 0)
  port             = 80
}

resource "aws_lb_target_group_attachment" "app2" {
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id        = element(var.app_instance_ids, 1)
  port             = 80
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

variable "app_instance_ids" {
  description = "List of EC2 instance IDs to register as targets"
  type        = list(string)
  default     = ["i-0123456789abcdef0", "i-0abcdef1234567890"]  # Replace with your actual instance IDs
}
```

Explanation
1. Provider Configuration: Specifies the AWS region.
2.Variables: Defines the env variable for environment identification and app_instance_ids variable to hold the list of EC2 instance IDs.
3. Target Group: Creates an AWS Target Group with the specified configuration, including health check settings.
4. Target Group Attachments: Registers the specified EC2 instances as targets in the target group.
5. VPC: Assumes the VPC already exists but includes its definition for completeness.

Replace the default values of the app_instance_ids variable with the actual instance IDs of your EC2 instances. Adjust the env variable as needed for different environments (e.g., aq or cp).

# Try 2
`aws_instance` id 직접 `variables.tf`에 입력하라는 점이 맘에 안 들어서 재질의

### Prompt

> what if I want to get app_instance_id from this code?
```hcl
resource "aws_instance" "app_instance" {
  count                      = 2
  ami                        = var.ami_id
  instance_type              = "t2.micro"
  key_name                   = aws_key_pair.key.key_name
  subnet_id                  = element([aws_subnet.subnet3.id, aws_subnet.subnet4.id], count.index)
  associate_public_ip_address = false

  tags = {
    Name = element(var.instance_tags, count.index)
  }

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = file("${path.module}/../user_data.sh")
}
```

### Response
To get the app_instance_id from the aws_instance resource that uses the count parameter, you can reference the specific instances using `aws_instance.app_instance[count.index].id`. Here is how you can modify the script to register these instances as targets in the AWS Target Group:

`main.tf`
```hcl
provider "aws" {
  region = "ap-northeast-2"
}

variable "env" {
  description = "Environment identifier (e.g., aq or cp)"
  type        = string
}

variable "ami_id" {
  description = "The AMI ID to use for the EC2 instance"
  type        = string
}

variable "instance_tags" {
  description = "List of tags for the EC2 instances"
  type        = list(string)
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

resource "aws_subnet" "subnet3" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "100.0.20.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "osj-terraform-with-${var.env}-prv-ap-a"
  }
}

resource "aws_subnet" "subnet4" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "100.0.30.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "osj-terraform-with-${var.env}-prv-ap-c"
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "osj-terraform-with-${var.env}-ec2-sg"
  description = "Security group for EC2 instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "key" {
  key_name   = "osj-terraform-with-${var.env}-key"
  public_key = tls_private_key.example.public_key_openssh
}

resource "aws_instance" "app_instance" {
  count                      = 2
  ami                        = var.ami_id
  instance_type              = "t2.micro"
  key_name                   = aws_key_pair.key.key_name
  subnet_id                  = element([aws_subnet.subnet3.id, aws_subnet.subnet4.id], count.index)
  associate_public_ip_address = false

  tags = {
    Name = element(var.instance_tags, count.index)
  }

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = file("${path.module}/../user_data.sh")
}

resource "aws_lb_target_group" "target_group" {
  name     = "osj-terraform-with-${var.env}-target-group"
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

resource "aws_lb_target_group_attachment" "app" {
  count             = length(aws_instance.app_instance)
  target_group_arn  = aws_lb_target_group.target_group.arn
  target_id         = aws_instance.app_instance[count.index].id
  port              = 80
}
```

`variables.tf`
```hcl
variable "env" {
  description = "Environment identifier (e.g., aq or cp)"
  type        = string
}

variable "ami_id" {
  description = "The AMI ID to use for the EC2 instance"
  type        = string
}

variable "instance_tags" {
  description = "List of tags for the EC2 instances"
  type        = list(string)
  default     = ["osj-terraform-with-aq-app-1", "osj-terraform-with-cp-app-2"]
}
```
Explanation
1. Provider Configuration: Specifies the AWS region.
2. Variables: Defines the env, ami_id, and instance_tags variables.
3. VPC and Subnets: Defines the VPC and subnets.
4. Security Group: Creates a security group allowing SSH access.
5. TLS Private Key and Key Pair: Generates a private key and creates a key pair.
6. EC2 Instances: Creates two EC2 instances using the count parameter.
7. Target Group: Creates an AWS Target Group with the specified configuration, including health check settings.
8. Target Group Attachments: Registers the created EC2 instances as targets in the target group using the count parameter to iterate over the instances.

Replace the ami_id and instance_tags values as needed. Adjust the env variable for different environments (e.g., aq or cp).
