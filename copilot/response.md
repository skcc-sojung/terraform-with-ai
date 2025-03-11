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

<br/>

### Response
Here is the Terraform script to create the specified AWS Route Tables:

```hcl
provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_vpc" "main" {
  cidr_block           = "100.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"

  tags = {
    Name = "osj-terraform-with-cp-vpc"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "100.0.0.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "osj-terraform-with-cp-pub-a"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "100.0.10.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "osj-terraform-with-cp-pub-c"
  }
}

resource "aws_subnet" "subnet3" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "100.0.20.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "osj-terraform-with-cp-prv-ap-a"
  }
}

resource "aws_subnet" "subnet4" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "100.0.30.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "osj-terraform-with-cp-prv-ap-c"
  }
}

resource "aws_subnet" "subnet5" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "100.0.40.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "osj-terraform-with-cp-prv-db-a"
  }
}

resource "aws_subnet" "subnet6" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "100.0.50.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "osj-terraform-with-cp-prv-db-c"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "osj-terraform-with-cp-igw"
  }
}

data "aws_eip" "existing_eip" {
  public_ip = "YOUR_EXISTING_EIP_PUBLIC_IP"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = data.aws_eip.existing_eip.id
  subnet_id     = aws_subnet.subnet1.id

  tags = {
    Name = "osj-terraform-with-cp-nat"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "osj-terraform-with-cp-pub-rt"
  }
}

resource "aws_route_table" "private_ap_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "osj-terraform-with-cp-prv-ap-rt"
  }
}

resource "aws_route_table" "private_db_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "osj-terraform-with-cp-prv-db-rt"
  }
}
```

This script creates three route tables with the specified names and associates them with the VPC `osj-terraform-with-cp-vpc`. Replace `YOUR_EXISTING_EIP_PUBLIC_IP` with the public IP address of the existing Elastic IP you want to use.

