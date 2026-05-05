resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id

  }


  tags = merge(var.common_tags,
    { Name = "public-route" }
  )
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags,
    { Name = "private-route" }
  )
}

resource "aws_main_route_table_association" "defualt" {
  vpc_id         = aws_vpc.main.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "public" {
  for_each = {
    for k, v in aws_subnet.main : k => v if strcontains(k, "public")
  }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id

}



resource "aws_route_table_association" "private" {
  for_each = {
    for k, v in aws_subnet.main : k => v if strcontains(k, "private")
  }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id

}
