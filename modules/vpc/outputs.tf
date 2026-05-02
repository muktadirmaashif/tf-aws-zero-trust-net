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
