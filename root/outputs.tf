# vpc/core
output "vpc_name" {
  value = module.vpc.vpc_name
}
output "vpc_cidr" {
  value = module.vpc.vpc_cidr
}
output "igw_name" {
  value = module.vpc.igw_name
}

output "available_zones" {
  value = module.vpc.available_zones
}

# vpc/core-subent-route
output "subnet_cidr" {
  value = module.vpc.subnet_cidr
}
output "subnet_az" {
  value = module.vpc.subnet_az
}
output "subnet_name" {
  value = module.vpc.subnet_name
}

# Route Table
output "public_route_subnet" {
  value = module.vpc.public_route_subnet
}
output "private_route_subnet" {
  value = module.vpc.private_route_subnet
}
