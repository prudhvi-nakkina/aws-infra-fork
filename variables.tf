variable "aws_region" {
    type = string
    description = "Closest AWS Region"
    default = "us-east-1"
}

variable "aws_profile" {
    type = string
    description = "AWS Profile to launch"
    default = "dev"
}

variable "cidr_block" {
    type = string
    description = "CIDR Block for VPC"
    default = "10.0.0.0/16"
}

variable "availability_zones" {
    type = list(string)
    description = "Availabillity zones for subnets"
    default = ["a", "b", "c"]
}

variable "vpc_name" {
    type = string
    description = "Name for VPC"
    default = "csye-vpc"
}

variable "public_subnet_name" {
    type = string
    description = "Public subnet name"
    default = "csye-public-subnet"
}

variable "private_subnet_name" {
    type = string
    description = "Private subnet name"
    default = "csye-private-subnet"
}

variable "gateway_name" {
    type = string
    description = "Gateway name"
    default = "csye-gateway"
}

variable "public_table_name" {
    type = string
    description = "public route table name"
    default = "csye-public-route-table"
}

variable "private_table_name" {
    type = string
    description = "private route table name"
    default = "csye-private-route-table"
}

variable "cidr_gateway" {
    type = string
    description = "subnet for gateway"
    default = "0.0.0.0/0"
}

variable "sub_prefix" {
    type = string
    description = "prefix for cidr"
    default = "10.0."
}

variable "sub_postfix" {
    type = string
    description = "postfix for cidr"
    default = ".0/24"
}