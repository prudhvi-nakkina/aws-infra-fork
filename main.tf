provider "aws" {
  region = var.aws_region
  profile = var.aws_profile
}

resource "aws_vpc" "main" {
  count = 3
  cidr_block = var.cidr_blocks[count.index]

  tags = {
    Name = "${var.vpc_name}-${count.index+1}"
  }
}

resource "aws_subnet" "public" {
  count = 9
  cidr_block = var.public_blocks[count.index]
  vpc_id = aws_vpc.main[floor(count.index / 3)].id
  availability_zone = var.availability_zones[(((count.index % 3) == 0) || count.index == 0)  ? 0 : (count.index % 2) == 0 ? 1 : 2]

  tags = {
    Name = "${var.public_subnet_name}-${count.index+1}"
  }
}

resource "aws_subnet" "private" {
  count = 9
  cidr_block = var.private_blocks[count.index]
  vpc_id = aws_vpc.main[floor(count.index / 3)].id
  availability_zone = var.availability_zones[(((count.index % 3) == 0) || count.index == 0)  ? 0 : (count.index % 2) == 0 ? 1 : 2]

  tags = {
    Name = "${var.private_subnet_name}-${count.index+1}"
  }
}

resource "aws_internet_gateway" "gw" {
  count = 3
  vpc_id = aws_vpc.main[count.index].id

  tags = {
    Name = "${var.gateway_name}-${count.index+1}"
  }
}

resource "aws_route_table" "public" {
  count = 3
  vpc_id = aws_vpc.main[count.index].id

  route {
    cidr_block = var.cidr_gateway
    gateway_id = aws_internet_gateway.gw[count.index].id
  }

  tags = {
    Name = "${var.public_table_name}-${count.index+1}"
  }
}

resource "aws_route_table_association" "public" {
  count = 9
  subnet_id = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[floor(count.index / 3)].id
}

resource "aws_route_table" "private" {

    count = 3

    vpc_id = aws_vpc.main[count.index].id

    tags = {
        Name = "${var.private_table_name}-${count.index+1}"
    }
  
}

resource "aws_route_table_association" "private" {
  count = 9
  subnet_id = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[floor(count.index / 3)].id
}