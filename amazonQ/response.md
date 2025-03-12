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
I'll help you add the Application Load Balancer and its Security Group configuration to your existing main.tf file. This configuration will integrate with your existing VPC and target group resources:

```hcl
#########################################
#                                       #
#       ALB Security Group              #
#                                       #
#########################################
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_prefix}-alb-sg"
  description = "security group for load balancer"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_prefix}-alb-sg"
  }
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

#########################################
#                                       #
#    Application Load Balancer          #
#                                       #
#########################################
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
```

This configuration:
1. Creates a Security Group for the ALB:
   * Allows inbound HTTP traffic (port 80) from anywhere
   * Allows all outbound traffic
   * Associates with your existing VPC

2. Creates an Application Load Balancer:
   * Internet-facing (public)
   * IPv4 address type
   * Placed in your public subnets
   * Uses the newly created security group
   * Associates with your existing target group
3. Creates an HTTP Listener:
   * Listens on port 80
   * Forwards traffic to your target group

Key features:
* Uses your existing variable structure ( var.project_prefix)
* Integrates with your existing VPC and subnet configuration
* References your existing target group for the listener
* Uses consistent naming conventions
* Includes proper tagging
* Follows security best practices for the security group configuration

Dependencies:
* Requires your existing VPC ( aws_vpc.main)
* Requires your existing subnets ( aws_subnet.subnets)
* Requires your existing target group ( aws_lb_target_group.app_tg)

The configuration assumes you're using the same subnet configuration structure from your existing code. If your subnet structure is different, you might need to adjust the subnet references in the ALB configuration.

Note: If you need to enable deletion protection for the ALB in production, change enable_deletion_protection to true. However, keep it false during development to allow easy cleanup.


<br/>

## TroubleShooting

Copilot으로 생성한 웹 서버는 브라우저에서 접속되는데
AmazonQ를 통해 생성한 웹 서버는 502 bad gateway 에러 뜨는 현상 발생

비교 분석하니 ec2 security group outbound 규칙에 모든 트래픽 허용이 빠져 있었음

### Prompt
```
Do I need a outbound rule for aws ec2 security group?
```

### Response
No, you don't need to explicitly define outbound rules for EC2 security groups because by default, AWS security groups include an implicit outbound rule that allows all outbound traffic (0.0.0.0/0).

Here are the key points about security group outbound rules:

1. Default Behavior:
```hcl
# This is implicitly created - you don't need to define it
resource "aws_security_group_rule" "all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ec2_sg.id
}
```

2. When to specify outbound rules:
* Only if you need to restrict outbound traffic
* When compliance requirements demand explicit traffic control
* When you want to document allowed outbound traffic

3. Example of restricted outbound rules:
```hcl
# Example of restricted outbound rules
resource "aws_security_group_rule" "restricted_outbound" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/16"]
  security_group_id = aws_security_group.ec2_sg.id
  description       = "Allow HTTPS to VPC only"
}
```

4. Best practices:
* Leave default outbound rules unless you have specific security requirements
* Document any custom outbound rules
* Consider using security group references instead of CIDR blocks when possible
* Use description field to document the purpose of rules

Therefore, for your EC2 security group, you can simply define the inbound rules and let AWS handle the default outbound behavior.

## Solution
답변에는 필요 없다 했지만 outbound rule 추가하고 ec2 지웠다가 다시 생성하니 해결
