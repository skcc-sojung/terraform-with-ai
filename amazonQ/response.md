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
I'll help you create the Terraform scripts for launching an EC2 instance with the specified configuration. Here's the solution: [1]

```hcl
# Key Pair
resource "aws_key_pair" "app_key_pair" {
  key_name   = "osj-terraform-with-${var.env}-key"
  public_key = tls_private_key.rsa.public_key_openssh
}

# Generate RSA key
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Save private key locally
resource "local_file" "private_key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "osj-terraform-with-${var.env}-key.pem"

  file_permission = "0400"
}

# Security Group
resource "aws_security_group" "ec2_sg" {
  name        = "osj-terraform-with-${var.env}-ec2-sg"
  description = "Security group for EC2 instance"
  vpc_id      = data.aws_vpc.existing_vpc.id

  tags = {
    Name = "osj-terraform-with-${var.env}-ec2-sg"
  }
}

# EC2 Instance
resource "aws_instance" "app_instance" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t2.micro"

  subnet_id                   = data.aws_subnet.private_subnet.id
  vpc_security_group_ids     = [aws_security_group.ec2_sg.id]
  key_name                   = aws_key_pair.app_key_pair.key_name
  associate_public_ip_address = false

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  user_data = file("../user_data.sh")

  tags = {
    Name = "osj-terraform-with-${var.env}-app-1"
  }
}

# Data source for Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Data source for existing VPC
data "aws_vpc" "existing_vpc" {
  tags = {
    Name = "osj-terraform-with-${var.env}-vpc"
  }
}

# Data source for existing subnet
data "aws_subnet" "private_subnet" {
  tags = {
    Name = "osj-terraform-with-${var.env}-prv-ap-${var.availability_zone}"
  }
}
```

And here's the corresponding variables file (`variables.tf`):
```hcl
variable "env" {
  description = "Environment identifier (aq or cp)"
  type        = string
}

variable "availability_zone" {
  description = "Availability zone identifier (a or c)"
  type        = string
}
```

This configuration:

1. Creates a new RSA key pair and saves the private key locally with proper permissions
2. Creates a new security group in the specified VPC
3. Launches an EC2 instance with:

  * Latest Amazon Linux 2023 AMI (x86_64)
  * t2.micro instance type
  * 8 GiB gp3 root volume
  * User data script from ../user_data.sh
  * Placement in the specified private subnet
  * No public IP address

4. Uses data sources to fetch existing VPC and subnet information
5. Uses variables for environment ( env) and availability zone to make the configuration reusable

Note: You'll need to:
1. Add security group rules based on your requirements using aws_security_group_rule resources
2. Ensure the user_data.sh file exists in the parent directory
3. Set the variables when applying the configuration:

```hcl
terraform apply -var="env=aq" -var="availability_zone=a"
```

The private key will be saved locally as "osj-terraform-with-{env}-key.pem" with read-only permissions (0400).

# Try 2
ec2 instance 2개 생성 요청으로 스크립트 변경

### Prompt
```
How can I create two EC2 instances using Terraform where only the subnet and tag name are different?
```
<br/>

### Response
I'll show you how to create multiple EC2 instances using Terraform with different subnets and names. Here are two approaches:

1. Using count with lists:
```hcl
locals {
  instance_configs = {
    "app-1" = {
      subnet_type = "prv-ap"
      az         = "a"
    }
    "app-2" = {
      subnet_type = "prv-ap"
      az         = "c"
    }
  }
}

# EC2 Instances
resource "aws_instance" "app_instances" {
  for_each = local.instance_configs

  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t2.micro"

  subnet_id                   = data.aws_subnet.private_subnets[each.key].id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  key_name                    = aws_key_pair.app_key_pair.key_name
  associate_public_ip_address = false

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  user_data = file("../user_data.sh")

  tags = {
    Name = "${var.project_prefix}-${each.key}"
  }
}

# Data source for private subnets
data "aws_subnet" "private_subnets" {
  for_each = local.instance_configs

  tags = {
    Name = "${var.project_prefix}-${each.value.subnet_type}-${each.value.az}"
  }
}
```
<br/>

2. Alternative approach using a more explicit map configuration:
```hcl
locals {
  instances = {
    app1 = {
      name       = "${var.project_prefix}-app-1"
      subnet_tag = "${var.project_prefix}-prv-ap-a"
    }
    app2 = {
      name       = "${var.project_prefix}-app-2"
      subnet_tag = "${var.project_prefix}-prv-ap-c"
    }
  }
}

# EC2 Instances
resource "aws_instance" "app_instances" {
  for_each = local.instances

  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t2.micro"

  subnet_id                   = data.aws_subnet.private_subnets[each.key].id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  key_name                    = aws_key_pair.app_key_pair.key_name
  associate_public_ip_address = false

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  user_data = file("../user_data.sh")

  tags = {
    Name = each.value.name
  }
}

# Data source for private subnets
data "aws_subnet" "private_subnets" {
  for_each = local.instances

  tags = {
    Name = each.value.subnet_tag
  }
}

# The rest of the configuration (key pair, security group, etc.) remains the same
resource "aws_key_pair" "app_key_pair" {
  key_name   = "${var.project_prefix}-key"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "private_key" {
  content         = tls_private_key.rsa.private_key_pem
  filename        = "${var.project_prefix}-key.pem"
  file_permission = "0400"
}

resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_prefix}-ec2-sg"
  description = "Security group for EC2 instances"
  vpc_id      = data.aws_vpc.existing_vpc.id

  tags = {
    Name = "${var.project_prefix}-ec2-sg"
  }
}
```
Both approaches use for_each to create multiple instances with different configurations. The main differences are:

1. The first approach uses a more structured configuration that separates the subnet type and availability zone
2. The second approach is more explicit and might be easier to understand for simpler configurations

Benefits of using for_each:
* Each instance is tracked individually in the Terraform state
* You can add or remove instances by modifying the map

* Changes to one instance don't affect the others
* You can easily reference individual instances using the map key

To use either configuration:

1. Define your variables in variables.tf:
```hcl
variable "project_prefix" {
  description = "Prefix for project resources"
  type        = string
}
```

2. Apply the configuration:
```hcl
terraform apply -var="project_prefix=osj-terraform-with-aq"
```

This will create two EC2 instances with:

* Same configuration (AMI, instance type, security group, key pair)
* Different subnets (one in az-a, one in az-c)
* Different names (app-1, app-2)
* Shared security group and key pair

You can easily add more instances by adding entries to the local.instances or local.instance_configs map.

<br/>

### TroubleShooting
AMI name pattern만으로는 정보가 불충분해 AMI volume snapshot과 설정한 volume 용량 부족으로 에러 발생

* 에러 입력
```
Error: creating EC2 Instance: InvalidBlockDeviceMapping: Volume of size 8GB is smaller than snapshot 'snap-08d0b57cd3c140f17', expect size>= 30GB
│ status code: 400, request id: b65d61a6-8ad2-4984-a363-2b64433a7f05
│
│ with aws_instance.app_instances["app-2"],
│ on main.tf line 168, in resource "aws_instance" "app_instances":
│ 168: resource "aws_instance" "app_instances" {
```

### Response
This error occurs because the AMI you're trying to use has a root volume snapshot that is 30GB, and you cannot create a volume smaller than the original snapshot size. Let's modify the root volume configuration to accommodate this requirement:
```hcl
resource "aws_instance" "app_instances" {
  for_each = local.instance_configs

  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t2.micro"

  subnet_id                   = data.aws_subnet.private_subnets[each.key].id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  key_name                    = aws_key_pair.app_key_pair.key_name
  associate_public_ip_address = false

  root_block_device {
    volume_size = 30  # Changed from 8 to 30 to match the minimum size requirement
    volume_type = "gp3"
  }

  user_data = file("../user_data.sh")

  tags = {
    Name = "${var.project_prefix}-${each.key}"
  }
}
```

Key points about EBS volume sizing:

1. You cannot create a volume smaller than the source AMI's snapshot size
2. The minimum root volume size for Amazon Linux 2023 AMI is 30GB
3. You can increase the volume size beyond 30GB, but not decrease it below this minimum
4. Even if you're only using a small portion of the volume, you must provision at least the minimum size

If you need to optimize costs:

* Consider using gp3 volume type as it offers better price/performance ratio
* Monitor actual usage to determine if you need to adjust the volume size for future deployments
* Remember that you're billed for the provisioned size, not the used size

The rest of your configuration can remain the same.



## Try 4
AMI ID 값으로 EC2에 AMI 지정하는 스크립트 요청

### Prompt
```
How do I specify an Amazon Machine Image (AMI) using its AMI ID when launching an EC2 instance with Terraform?
```

### Response
I'll show you several ways to specify an AMI ID when launching EC2 instances in Terraform:
1. Direct AMI ID specification:
```hcl
resource "aws_instance" "app_instance" {
  ami           = "ami-0889a44b331db0194"  # Replace with your AMI ID
  instance_type = "t2.micro"
  # ... other configuration ...
}
```

2. Using a variable:
```hcl
# In variables.tf
variable "ami_id" {
  description = "The ID of the AMI to use for the EC2 instance"
  type        = string
  default     = "ami-0889a44b331db0194"  # Optional default value
}

# In main.tf
resource "aws_instance" "app_instance" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  # ... other configuration ...
}
```

3. Using a data source to find the latest AMI by name pattern:
```hcl
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]  # AWS account ID that owns the AMI

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]  # AMI name pattern
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "app_instance" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t2.micro"
  # ... other configuration ...
}
```

4. Using AWS Systems Manager Parameter Store:
```hcl
data "aws_ssm_parameter" "amazon_linux_2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "app_instance" {
  ami           = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type = "t2.micro"
  # ... other configuration ...
}
```

5. Using locals for multiple AMIs:
```hcl
locals {
  amis = {
    amazon_linux_2023 = "ami-0889a44b331db0194"
    ubuntu_22_04      = "ami-0735c191cf914754d"
  }
}

resource "aws_instance" "app_instance" {
  ami           = local.amis.amazon_linux_2023
  instance_type = "t2.micro"
  # ... other configuration ...
}
```

6. Using a map variable for different regions:
```hcl
variable "amis" {
  type = map(string)
  default = {
    "us-east-1" = "ami-0889a44b331db0194"
    "us-west-2" = "ami-0735c191cf914754d"
  }
}

resource "aws_instance" "app_instance" {
  ami           = var.amis[data.aws_region.current.name]
  instance_type = "t2.micro"
  # ... other configuration ...
}

data "aws_region" "current" {}
```

Best practices:
1. Use data sources or SSM parameters when possible to automatically get the latest AMI version
2. Document the AMI selection in your code comments
3. Consider using variables to make the configuration more flexible
4. Use AMI filters to ensure you get the right type of AMI
5. Include the owner ID when using data sources to ensure you're using trusted AMIs
6. Consider version constraints when using latest AMIs

Example combining multiple best practices:
```hcl
# Define AMI options
variable "ami_type" {
  description = "Type of AMI to use (al2023 or ubuntu)"
  type        = string
  default     = "al2023"
}

locals {
  ami_patterns = {
    al2023 = {
      owners = ["amazon"]
      name_pattern = ["al2023-ami-*-x86_64"]
    }
    ubuntu = {
      owners = ["099720109477"]  # Canonical's AWS account ID
      name_pattern = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
    }
  }
}

# Data source for AMI lookup
data "aws_ami" "selected" {
  most_recent = true
  owners      = local.ami_patterns[var.ami_type].owners

  filter {
    name   = "name"
    values = local.ami_patterns[var.ami_type].name_pattern
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# EC2 instance using the selected AMI
resource "aws_instance" "app_instance" {
  ami           = data.aws_ami.selected.id
  instance_type = "t2.micro"

  # Add a tag to track which AMI was used
  tags = {
    Name    = "app-instance"
    AMI_ID  = data.aws_ami.selected.id
    AMI_Name = data.aws_ami.selected.name
  }
}
```

This configuration allows you to:

* Choose between different AMI types using a variable
* Automatically get the latest version of the chosen AMI
* Track which AMI was used in the instance tags
* Ensure you're using trusted AMIs by specifying owner IDs
* Filter for specific AMI characteristics
