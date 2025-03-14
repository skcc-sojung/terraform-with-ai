provider "aws" {
  region = "ap-northeast-2"
}

#########################################
#                                       #
#               Network                 #
#                                       #
#########################################
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


#########################################
#                                       #
#              Web Server               #
#                                       #
#########################################
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

resource "aws_lb_target_group_attachment" "app" {
  count             = length(aws_instance.app_instance)
  target_group_arn  = aws_lb_target_group.target_group.arn
  target_id         = aws_instance.app_instance[count.index].id
  port              = 80
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
