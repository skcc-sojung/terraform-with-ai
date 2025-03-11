provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_vpc" "main" {
  cidr_block = "100.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  instance_tenancy = "default"

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
  public_ip = "3.37.13.99"
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

resource "aws_route_table_association" "public_rt_assoc1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rt_assoc2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_ap_rt_assoc1" {
  subnet_id      = aws_subnet.subnet3.id
  route_table_id = aws_route_table.private_ap_rt.id
}

resource "aws_route_table_association" "private_ap_rt_assoc2" {
  subnet_id      = aws_subnet.subnet4.id
  route_table_id = aws_route_table.private_ap_rt.id
}

resource "aws_route_table_association" "private_db_rt_assoc1" {
  subnet_id      = aws_subnet.subnet5.id
  route_table_id = aws_route_table.private_db_rt.id
}

resource "aws_route_table_association" "private_db_rt_assoc2" {
  subnet_id      = aws_subnet.subnet6.id
  route_table_id = aws_route_table.private_db_rt.id
}

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