provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

resource "aws_vpc" "main" {
  cidr_block = var.cidr_block

  tags = {
    Name = "${var.vpc_name}-${var.cidr_block}"
  }
}

resource "aws_subnet" "public" {
  count             = 3
  cidr_block        = "${var.sub_prefix}${count.index + 1}${var.sub_postfix}"
  vpc_id            = aws_vpc.main.id
  availability_zone = "${var.aws_region}${var.availability_zones[count.index]}"

  tags = {
    Name = "${var.public_subnet_name}-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count             = 3
  cidr_block        = "${var.sub_prefix}${count.index + 4}${var.sub_postfix}"
  vpc_id            = aws_vpc.main.id
  availability_zone = "${var.aws_region}${var.availability_zones[count.index]}"

  tags = {
    Name = "${var.private_subnet_name}-${count.index + 1}"
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
  count          = 3
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.private_table_name}-${var.cidr_block}"
  }

}

resource "aws_route_table_association" "private" {
  count          = 3
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Create security group for EC2 instance
resource "aws_security_group" "application" {
  name_prefix = var.security_group_name
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = var.ports[0]
    to_port     = var.ports[0]
    protocol    = var.protocol
    cidr_blocks = [var.cidr_gateway]
  }

  ingress {
    from_port   = var.ports[1]
    to_port     = var.ports[1]
    protocol    = var.protocol
    cidr_blocks = [var.cidr_gateway]
  }

  ingress {
    from_port   = var.ports[2]
    to_port     = var.ports[2]
    protocol    = var.protocol
    cidr_blocks = [var.cidr_gateway]
  }

  ingress {
    from_port   = var.ports[3]
    to_port     = var.ports[3]
    protocol    = var.protocol
    cidr_blocks = [var.cidr_gateway]
  }

  egress {
    from_port   = var.ports[4]
    to_port     = var.ports[4]
    protocol    = var.eprotocol
    cidr_blocks = [var.cidr_gateway]
  }
}

resource "aws_key_pair" "app_keypair" {
  key_name   = var.keypair_name
  public_key = file(var.keypair_path)
}

resource "aws_ebs_volume" "ebs_volume" {
  availability_zone = "${var.aws_region}${var.availability_zones[0]}"
  size              = var.ebs_volume_size
  type              = var.ebs_volume_type
  tags = {
    Name = var.ebs_volume_name
  }
}

data "aws_ami" "latest_ami" {
  most_recent = true
  filter {
    name   = "name"
    values = ["${var.ami_name}-*"]
  }
}

# Launch EC2 instance
resource "aws_instance" "csye_ec2" {
  ami                    = data.aws_ami.latest_ami.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.application.id]
  tags = {
    Name = var.ec2_name
  }
  key_name = aws_key_pair.app_keypair.key_name

  associate_public_ip_address = true
  disable_api_termination     = false

  root_block_device {
    delete_on_termination = true
  }

  # Add SSH key to the instance
  connection {
    type        = var.connection_type
    user        = var.user
    private_key = file(var.privatekey_path)
    timeout     = var.ssh_timeout
    host        = self.public_ip
  }
}

resource "aws_volume_attachment" "ebsAttach" {

  device_name = var.device_name
  volume_id   = aws_ebs_volume.ebs_volume.id
  instance_id = aws_instance.csye_ec2.id

}

# Allocate Elastic IP
resource "aws_eip" "ec2_eip" {
  vpc = true
}

# Associate Elastic IP with EC2 instance
resource "aws_eip_association" "ec2_eip_assoc" {
  instance_id   = aws_instance.csye_ec2.id
  allocation_id = aws_eip.ec2_eip.id
}

# provider "aws" {
#   region = var.aws_region
#   profile = var.aws_profile
# }

# resource "aws_vpc" "main" {
#   count = 3
#   cidr_block = var.cidr_blocks[count.index]

#   tags = {
#     Name = "${var.vpc_name}-${count.index+1}"
#   }
# }

# resource "aws_subnet" "public" {
#   count = 9
#   cidr_block = var.public_blocks[count.index]
#   vpc_id = aws_vpc.main[floor(count.index / 3)].id
#   availability_zone = var.availability_zones[(((count.index % 3) == 0) || count.index == 0)  ? 0 : (count.index % 2) == 0 ? 1 : 2]

#   tags = {
#     Name = "${var.public_subnet_name}-${count.index+1}"
#   }
# }

# resource "aws_subnet" "private" {
#   count = 9
#   cidr_block = var.private_blocks[count.index]
#   vpc_id = aws_vpc.main[floor(count.index / 3)].id
#   availability_zone = var.availability_zones[(((count.index % 3) == 0) || count.index == 0)  ? 0 : (count.index % 2) == 0 ? 1 : 2]

#   tags = {
#     Name = "${var.private_subnet_name}-${count.index+1}"
#   }
# }

# resource "aws_internet_gateway" "gw" {
#   count = 3
#   vpc_id = aws_vpc.main[count.index].id

#   tags = {
#     Name = "${var.gateway_name}-${count.index+1}"
#   }
# }

# resource "aws_route_table" "public" {
#   count = 3
#   vpc_id = aws_vpc.main[count.index].id

#   route {
#     cidr_block = var.cidr_gateway
#     gateway_id = aws_internet_gateway.gw[count.index].id
#   }

#   tags = {
#     Name = "${var.public_table_name}-${count.index+1}"
#   }
# }

# resource "aws_route_table_association" "public" {
#   count = 9
#   subnet_id = aws_subnet.public[count.index].id
#   route_table_id = aws_route_table.public[floor(count.index / 3)].id
# }

# resource "aws_route_table" "private" {

#     count = 3

#     vpc_id = aws_vpc.main[count.index].id

#     tags = {
#         Name = "${var.private_table_name}-${count.index+1}"
#     }

# }

# resource "aws_route_table_association" "private" {
#   count = 9
#   subnet_id = aws_subnet.private[count.index].id
#   route_table_id = aws_route_table.private[floor(count.index / 3)].id
# }