# main.tf

#########################################
#                                       #
#               Network                 #
#                                       #
#########################################
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_prefix}-vpc"
  }
}

resource "aws_subnet" "subnets" {
  for_each = var.subnet_config

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone

  tags = {
    Name = "${var.project_prefix}-${each.value.subnet_type}-${substr(each.value.availability_zone, -1, 1)}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "osj-terraform-with-aq-igw"
  }
}

# Create NAT Gateway
resource "aws_nat_gateway" "main" {
  allocation_id = data.aws_eip.existing_eip.id
  subnet_id = aws_subnet.subnets["pub_a"].id

  tags = {
    Name = "${var.project_prefix}-nat"
  }

  depends_on = [aws_internet_gateway.main]
}

# Create route tables
resource "aws_route_table" "this" {
  for_each = var.route_tables
  vpc_id   = aws_vpc.main.id

  tags = {
    Name = "${var.project_prefix}-${replace(each.key, "_", "-")}-rt"
  }
}

# Route table associations using dynamic configuration
resource "aws_route_table_association" "subnet_associations" {
  for_each = var.subnet_config

  subnet_id = aws_subnet.subnets[each.key].id
  route_table_id = aws_route_table.this[
    lookup({
      "pub"    = "pub"
      "prv-ap" = "prv-ap"
      "prv-db" = "prv-db"
    }, each.value.subnet_type)
  ].id
}

# Create routes using the flattened configuration
resource "aws_route" "routes" {
  for_each = local.route_configurations

  route_table_id         = aws_route_table.this[each.value.rt_key].id
  destination_cidr_block = each.value.cidr_block

  # Conditionally set the gateway_id or nat_gateway_id
  gateway_id     = each.value.gateway_key == "igw" ? local.gateway_ids["igw"] : null
  nat_gateway_id = each.value.gateway_key == "nat" ? local.gateway_ids["nat"] : null

  depends_on = [
    aws_route_table.this,
    aws_internet_gateway.main,
    aws_nat_gateway.main
  ]
}

locals {
  # Map gateway types to their resource IDs
  gateway_ids = {
    igw = aws_internet_gateway.main.id
    nat = aws_nat_gateway.main.id
  }

  # Create a flattened map of routes for easier iteration
  route_configurations = {
    for pair in flatten([
      for rt_key, rt in var.route_tables : [
        for route in rt.routes : {
          rt_key      = rt_key
          cidr_block  = route.cidr_block
          gateway_key = route.gateway_key
        }
      ]
    ]) : "${pair.rt_key}-${pair.cidr_block}" => pair
  }
}

data "aws_eip" "existing_eip" {
  id = var.existing_eip_id
}

#########################################
#                                       #
#              Web Server               #
#                                       #
#########################################
# Key Pair
resource "aws_key_pair" "app_key_pair" {
  key_name   = "${var.project_prefix}-key"
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
  filename = "${var.project_prefix}-key.pem"

  file_permission = "0400"
}

# Security Group
resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_prefix}-ec2-sg"
  description = "Security group for EC2 instance"
  vpc_id      = data.aws_vpc.existing_vpc.id

  tags = {
    Name = "${var.project_prefix}-ec2-sg"
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "${var.project_prefix}-alb-sg"
  description = "security group for load balancer"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_prefix}-alb-sg"
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

resource "aws_security_group_rule" "all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.aws_security_group.existing.id
}

resource "aws_security_group_rule" "alb_http_inbound" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
  description       = "Allow HTTP inbound traffic"
}

resource "aws_security_group_rule" "alb_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
  description       = "Allow all outbound traffic"
}

# EC2 Instances
resource "aws_instance" "app_instances" {
  for_each = local.instance_configs

  ami           = var.ami_id
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

# Target Group
resource "aws_lb_target_group" "app_tg" {
  name        = "${var.project_prefix}-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 3
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_prefix}-target-group"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Target Group Attachments
resource "aws_lb_target_group_attachment" "apps" {
  for_each = data.aws_instance.apps

  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = each.value.id
  port             = 80

  depends_on = [aws_lb_target_group.app_tg]
}

# Application load balancer
resource "aws_lb" "app_alb" {
  name               = "${var.project_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets = [
    aws_subnet.subnets["pub_a"].id,
    aws_subnet.subnets["pub_c"].id
  ]

  enable_deletion_protection = false
  ip_address_type          = "ipv4"

  tags = {
    Name = "${var.project_prefix}-alb"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }

  tags = {
    Name = "${var.project_prefix}-http-listener"
  }
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
      description = "${var.project_prefix}-pub-a-CIDR"
    }
    pub_c = {
      type        = "ingress"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["100.0.10.0/24"]
      description = "${var.project_prefix}-pub-c-CIDR"
    }
  }
}

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

# Data source to fetch existing security group
data "aws_security_group" "existing" {
  tags = {
    Name = "${var.project_prefix}-ec2-sg"
  }
}

# Data source for existing VPC
data "aws_vpc" "existing_vpc" {
  tags = {
    Name = "${var.project_prefix}-vpc"
  }
}

# Data source for private subnets
data "aws_subnet" "private_subnets" {
  for_each = local.instance_configs

  tags = {
    Name = "${var.project_prefix}-${each.value.subnet_type}-${each.value.az}"
  }
}

# Data source for existing EC2 instances
data "aws_instance" "apps" {
  for_each = local.instance_configs

  filter {
    name   = "tag:Name"
    values = ["${var.project_prefix}-${each.key}"]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}



