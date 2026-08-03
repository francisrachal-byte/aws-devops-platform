output "vpc_id" {
  value = aws_vpc.this.id
}
output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "availability_zones" {
  description = "Availability Zones used by the subnets"
  value = [
    for subnet in aws_subnet.public : subnet.availability_zone
  ]
}