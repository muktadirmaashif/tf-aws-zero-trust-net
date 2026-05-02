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
