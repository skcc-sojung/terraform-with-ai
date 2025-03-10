# outputs.tf
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "subnet_ids" {
  description = "Map of subnet names to subnet IDs"
  value = {
    for k, v in aws_subnet.subnets : k => {
      id                = v.id
      cidr_block        = v.cidr_block
      availability_zone = v.availability_zone
    }
  }
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value = [
    for subnet in aws_subnet.subnets :
    subnet.id if subnet.map_public_ip_on_launch
  ]
}

output "private_app_subnet_ids" {
  description = "List of private application subnet IDs"
  value = [
    for subnet in aws_subnet.subnets :
    subnet.id if contains(split("-", subnet.tags["Name"]), "ap")
  ]
}

output "private_db_subnet_ids" {
  description = "List of private database subnet IDs"
  value = [
    for subnet in aws_subnet.subnets :
    subnet.id if contains(split("-", subnet.tags["Name"]), "db")
  ]
}
