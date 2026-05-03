output "vpc_name" {
  value = aws_vpc.main.tags["Name"]
}

output "vpc_cidr" {
  value = aws_vpc.main.cidr_block
}

output "igw_name" {
  value = aws_internet_gateway.main_igw.tags["Name"]
}

output "available_zones" {
  value = data.aws_availability_zones.available.names
}

# Subent 
output "subnet_cidr" {
  value = { for k, v in aws_subnet.main : k => v.cidr_block }
}
output "subnet_az" {
  value = { for k, v in aws_subnet.main : k => v.availability_zone }
}
output "subnet_name" {
  value = aws_subnet.main.tags["Name"]
}

# Route Table
output "public_route_subnet" {
  value = aws_route_table_association.public.subnet_id
}
output "private_route_subnet" {
  value = aws_route_table_association.private.subnet_id
}
