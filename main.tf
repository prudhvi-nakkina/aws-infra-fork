provider "aws" {
  region = var.aws_region
  profile = var.aws_profile
}

resource "aws_vpc" "main" {
  cidr_block = var.cidr_block

  tags = {
    Name = "${var.vpc_name}-${var.cidr_block}"
  }
}

resource "aws_subnet" "public" {
  count = 3
  cidr_block = "${var.sub_prefix}${count.index+1}${var.sub_postfix}"
  vpc_id = aws_vpc.main.id
  availability_zone = "${var.aws_region}${var.availability_zones[count.index]}"

  tags = {
    Name = "${var.public_subnet_name}-${count.index+1}"
  }
}

resource "aws_subnet" "private" {
  count = 3
  cidr_block = "${var.sub_prefix}${count.index+4}${var.sub_postfix}"
  vpc_id = aws_vpc.main.id
  availability_zone = "${var.aws_region}${var.availability_zones[count.index]}"

  tags = {
    Name = "${var.private_subnet_name}-${count.index+1}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.gateway_name}-${var.cidr_block}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = var.cidr_gateway
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.public_table_name}-${var.cidr_block}"
  }
}

resource "aws_route_table_association" "public" {
  count = 3
  subnet_id = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {

    vpc_id = aws_vpc.main.id

    tags = {
        Name = "${var.private_table_name}-${var.cidr_block}"
    }
  
}

resource "aws_route_table_association" "private" {
  count = 3
  subnet_id = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}