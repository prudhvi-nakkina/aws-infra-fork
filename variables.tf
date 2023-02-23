variable "aws_region" {
  type        = string
  description = "Closest AWS Region"
  default     = "us-east-1"
}

variable "aws_profile" {
  type        = string
  description = "AWS Profile to launch"
  default     = "dev"
}

variable "cidr_block" {
  type        = string
  description = "CIDR Block for VPC"
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  type        = list(string)
  description = "Availabillity zones for subnets"
  default     = ["a", "b", "c"]
}

variable "vpc_name" {
  type        = string
  description = "Name for VPC"
  default     = "csye-vpc"
}

variable "public_subnet_name" {
  type        = string
  description = "Public subnet name"
  default     = "csye-public-subnet"
}

variable "private_subnet_name" {
  type        = string
  description = "Private subnet name"
  default     = "csye-private-subnet"
}

variable "gateway_name" {
  type        = string
  description = "Gateway name"
  default     = "csye-gateway"
}

variable "public_table_name" {
  type        = string
  description = "public route table name"
  default     = "csye-public-route-table"
}

variable "private_table_name" {
  type        = string
  description = "private route table name"
  default     = "csye-private-route-table"
}

variable "cidr_gateway" {
  type        = string
  description = "subnet for gateway"
  default     = "0.0.0.0/0"
}

variable "sub_prefix" {
  type        = string
  description = "prefix for cidr"
  default     = "10.0."
}

variable "sub_postfix" {
  type        = string
  description = "postfix for cidr"
  default     = ".0/24"
}

variable "security_group_name" {
  type        = string
  description = "security group name"
  default     = "applicatiom"
}

variable "ports" {
  type        = list(number)
  description = "list of parts"
  default     = [22, 80, 443, 5000, 0]
}

variable "protocol" {
  type        = string
  description = "protocol name"
  default     = "tcp"
}

variable "eprotocol" {
  type        = string
  description = "egress protocol name"
  default     = "-1"
}

variable "keypair_name" {
  type        = string
  description = "key-pair name"
  default     = "app_keypair"
}

variable "keypair_path" {
  type        = string
  description = "key-pair path"
  default     = "~/.ssh/id_rsa.pub"
}

variable "ebs_volume_size" {
  type        = number
  description = "ebs volume size"
  default     = 50
}

variable "ebs_volume_type" {
  type        = string
  description = "ebs volume type"
  default     = "gp2"
}

variable "instance_type" {
  type        = string
  description = "ebs instance type"
  default     = "t2.micro"
}

variable "connection_type" {
  type        = string
  description = "connection type"
  default     = "ssh"
}

variable "user" {
  type        = string
  description = "user"
  default     = "ec2-user"
}

variable "privatekey_path" {
  type        = string
  description = "path for private key"
  default     = "~/.ssh/id_rsa"
}

variable "ssh_timeout" {
  type        = string
  description = "timeout for ssh"
  default     = "2h"
}

variable "device_name" {
  type        = string
  description = "name of device"
  default     = "/dev/sdh"
}

variable "ebs_volume_name" {
  type        = string
  description = "ebs volume name"
  default     = "ebs_volume"
}

variable "ec2_name" {
  type        = string
  description = "name of ec2 instance"
  default     = "csye_ec2"
}

variable "ami_name" {
  type        = string
  description = "ami name for ec2 instance"
  default     = "amazon-linux-2-node-mysql-ami"
}
# variable "aws_region" {
#     type = string
#     description = "Closest AWS Region"
#     default = "us-east-1"
# }

# variable "aws_profile" {
#     type = string
#     description = "AWS Profile to launch"
#     default = "dev"
# }

# variable "cidr_blocks" {
#     type = list(string)
#     description = "CIDR Blocks for VPC"
#     default = ["10.0.0.0/16", "10.1.0.0/16", "10.2.0.0/16"]
# }

# variable "availability_zones" {
#     type = list(string)
#     description = "Availabillity zones for subnets"
#     default = ["us-east-1a", "us-east-1b", "us-east-1c"]
# }

# variable "public_blocks" {
#     type = list(string)
#     description = "Public Subnets"
#     default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24", "10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
# }

# variable "private_blocks" {
#     type = list(string)
#     description = "Private Subnets"
#     default = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24", "10.1.4.0/24", "10.1.5.0/24", "10.1.6.0/24", "10.2.4.0/24", "10.2.5.0/24", "10.2.6.0/24"]
# }

# variable "vpc_name" {
#     type = string
#     description = "Name for VPC"
#     default = "csye-vpc"
# }

# variable "public_subnet_name" {
#     type = string
#     description = "Public subnet name"
#     default = "csye-public-subnet"
# }

# variable "private_subnet_name" {
#     type = string
#     description = "Private subnet name"
#     default = "csye-private-subnet"
# }

# variable "gateway_name" {
#     type = string
#     description = "Gateway name"
#     default = "csye-gateway"
# }

# variable "public_table_name" {
#     type = string
#     description = "public route table name"
#     default = "csye-public-route-table"
# }

# variable "private_table_name" {
#     type = string
#     description = "private route table name"
#     default = "csye-private-route-table"
# }

# variable "cidr_gateway" {
#     type = string
#     description = "subnet for gateway"
#     default = "0.0.0.0/0"
# }