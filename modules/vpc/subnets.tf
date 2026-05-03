data "aws_availability_zones" "available" {
  state = "available"
}


locals {
  subnet_map = {
    public_net  = cidrsubnet(var.vpc_cidr, 8, 1)
    private_net = cidrsubnet(var.vpc_cidr, 8, 10)
  }

  # slice(list, startIndex, endIndex). as one subnet = one gw, 
  # len(subnet) = 3, len(az) = 4, then slice = list of first 3 azs. 
  az_list = slice(data.aws_availability_zones.available.names, 0, min(length(local.subnet_map), length(data.aws_availability_zones.available.names)))
}

resource "aws_subnet" "main" {
  vpc_id = aws_vpc.main.id

  for_each          = local.subnet_map
  cidr_block        = each.value
  availability_zone = local.az_list[index(keys(local.subnet_map), each.key)]

  map_public_ip_on_launch = contains(split("-", each.key), "public")

  tags = merge(var.common_tags,
    { Name = "${each.key}-subnet" }
  )
}
