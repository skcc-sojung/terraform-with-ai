# Try 1
### Prompt

> Write Terraform scripts to create an AWS EC2 instance with the following configuration:
> * Name: osj-terraform-with-{aq | cp}-app-1
> * Amazon Machine Image (AMI): Amazon Linux 2023 AMI
> * Architecture: 64-bit (x86)
> * Instance Type: t2.micro
> * Key Pair
>     - Create a new key pair
>     - Key pair name: osj-terraform-with-{aq | cp}-key
>     - Key type: RSA
>     - Private key file format: .pem
> * Network Settings:
>     - VPC: osj-terraform-with-{aq | cp}-vpc
>     - Subnet: osj-terraform-with-{aq | cp}-prv-ap-{a|c}
>     - Auto-assign public IP: disabled
> * Security Group:
>     - Create a new security group
>     - Security group name: osj-terraform-with-{aq | cp}-ec2-sg
> * Storage:
>     - Root volume size: 8 GiB
>     - Volume type: gp3
> * Advanced Settings:
>     - Use the file ../user_data.sh as the user data script
> 
> Use Terraform resources such as aws_instance, aws_key_pair, aws_security_group, and necessary dependencies. Assume the VPC and subnet already exist.

<br/>

### Response
Here are the Terraform scripts to create an AWS EC2 instance with the specified configuration:

`main.tf`
```hcl
provider "aws" {
  region = "ap-northeast-2"
}

variable "env" {
  description = "Environment identifier (e.g., aq or cp)"
  type        = string
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_key_pair" "key" {
  key_name   = "osj-terraform-with-${var.env}-key"
  key_type   = "rsa"
  public_key = file("${path.module}/public_key.pub")
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

resource "aws_instance" "app_instance" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.key.key_name
  subnet_id                   = aws_subnet.prv_ap_a.id
  associate_public_ip_address = false

  tags = {
    Name = "osj-terraform-with-${var.env}-app-1"
  }

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = file("${path.module}/../user_data.sh")
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

resource "aws_subnet" "prv_ap_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "100.0.20.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "osj-terraform-with-${var.env}-prv-ap-a"
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

`public_key.pub`
```hcl
# Replace this with your actual public key content
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAr... user@hostname
```

`../user_data.sh`
```hcl
#!/bin/bash
# Your user data script content goes here
```

Explanation
1. Provider Configuration: Specifies the AWS region.
2. Variables: Defines the env variable for environment identification.
3. AMI Data Source: Retrieves the most recent Amazon Linux 2 AMI.
4. Key Pair: Creates a new RSA key pair and uses the public key from public_key.pub.
5. Security Group: Creates a security group allowing SSH access.
6. EC2 Instance: Creates an EC2 instance with the specified configuration, including user data from ../user_data.sh.
7. VPC and Subnet: Assumes the VPC and subnet already exist but includes their definitions for completeness.

Replace the placeholder in public_key.pub with your actual public key content. Adjust the paths and content of ../user_data.sh as needed.

Similar code found with 2 license types - View matches

<br/>

# Try 2
ec2 instance 2개 생성 요청으로 스크립트 변경

### Prompt
```
How can I create two EC2 instances using Terraform where only the subnet and tag name are different?
```
<br/>

### Response
To create two EC2 instances using Terraform where only the subnet and tag name are different, you can use Terraform's count parameter to create multiple instances with different configurations. Here's an example:

`main.tf`
```hcl
provider "aws" {
  region = "ap-northeast-2"
}

variable "env" {
  description = "Environment identifier (e.g., aq or cp)"
  type        = string
}

variable "subnets" {
  description = "List of subnets for the EC2 instances"
  type        = list(string)
}

variable "instance_tags" {
  description = "List of tags for the EC2 instances"
  type        = list(string)
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_key_pair" "key" {
  key_name   = "osj-terraform-with-${var.env}-key"
  key_type   = "rsa"
  public_key = file("${path.module}/public_key.pub")
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

resource "aws_instance" "app_instance" {
  count                      = length(var.subnets)
  ami                        = data.aws_ami.amazon_linux.id
  instance_type              = "t2.micro"
  key_name                   = aws_key_pair.key.key_name
  subnet_id                  = element(var.subnets, count.index)
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

variable "subnets" {
  description = "List of subnets for the EC2 instances"
  type        = list(string)
  default     = ["subnet-12345678", "subnet-87654321"]  # Replace with your actual subnet IDs
}

variable "instance_tags" {
  description = "List of tags for the EC2 instances"
  type        = list(string)
  default     = ["osj-terraform-with-aq-app-1", "osj-terraform-with-cp-app-2"]
}
```

`public_key.pub`
```hcl
# Replace this with your actual public key content
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAr... user@hostname
```

`../user_data.sh`
```hcl
#!/bin/bash
# Your user data script content goes here
```

Explanation
1. Provider Configuration: Specifies the AWS region.
2. Variables: Defines the env, subnets, and instance_tags variables.
3. AMI Data Source: Retrieves the most recent Amazon Linux 2 AMI.
4. Key Pair: Creates a new RSA key pair and uses the public key from public_key.pub.
5. Security Group: Creates a security group allowing SSH access.
6. EC2 Instances: Creates multiple EC2 instances using the count parameter, with different subnets and tags.
7. VPC: Assumes the VPC already exists but includes its definition for completeness.

Replace the placeholder in public_key.pub with your actual public key content. Adjust the paths and content of ../user_data.sh as needed.

<br/>

# Try 3
private key 생성 직접 요청

### Prompt
```
How can I make a private_key directly in terraform script?
```

### Response
To generate a private key directly in Terraform, you can use the tls_private_key resource. This resource allows you to create a private key and then use it to create an AWS key pair. Here is an example of how to do this:

`main.tf`
```hcl
provider "aws" {
  region = "ap-northeast-2"
}

variable "env" {
  description = "Environment identifier (e.g., aq or cp)"
  type        = string
}

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "key" {
  key_name   = "osj-terraform-with-${var.env}-key"
  public_key = tls_private_key.example.public_key_openssh
}

resource "local_file" "private_key" {
  content  = tls_private_key.example.private_key_pem
  filename = "${path.module}/osj-terraform-with-${var.env}-key.pem"
  sensitive = true
}

output "private_key_pem" {
  value     = tls_private_key.example.private_key_pem
  sensitive = true
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
3. TLS Private Key: Generates a new RSA private key using the tls_private_key resource.
4. AWS Key Pair: Creates a new AWS key pair using the public key generated by the tls_private_key resource.
5. Local File: Saves the private key to a file named osj-terraform-with-${var.env}-key.pem in the current module directory.
6. Output: Outputs the private key in PEM format. The sensitive attribute ensures that the private key is not displayed in the Terraform output.

This setup ensures that the private key is generated directly in Terraform and saved in a .pem file format. The private key is also outputted as a sensitive value to avoid displaying it in the Terraform output.
