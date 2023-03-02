aws_region          = "us-east-1"
aws_profile         = "dev"
cidr_block          = "10.0.0.0/16"
availability_zones  = ["a", "b", "c"]
sub_prefix          = "10.0."
sub_postfix         = ".0/24"
vpc_name            = "csye-vpc"
public_subnet_name  = "csye-public-subnet"
private_subnet_name = "csye-private-subnet"
gateway_name        = "csye-gateway"
public_table_name   = "csye-public-route-table"
private_table_name  = "csye-private-route-table"
cidr_gateway        = "0.0.0.0/0"
security_group_name = "application"
ports               = [22, 80, 443, 5000, 0]
protocol            = "tcp"
eprotocol           = "-1"
keypair_name        = "app_keypair"
keypair_path        = "~/.ssh/id_rsa.pub"
ebs_volume_size     = 50
ebs_volume_type     = "gp2"
instance_type       = "t2.micro"
connection_type     = "ssh"
user                = "ec2-user"
privatekey_path     = "~/.ssh/id_rsa"
ssh_timeout         = "2h"
device_name         = "/dev/sdh"
ebs_volume_name     = "ebs_volume"
bucket_name         = "csye-bucket-"
ec2_name            = "csye_ec2"
ami_name            = "amazon-linux-2-node-mysql-ami"
DB_USERNAME         = "csye6225"
DB_PASSWORD         = "Leomessi1!"
DB_DIALECT          = "mysql"
DB_PORT             = 3306