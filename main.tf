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
  description = "My security group for EC2 instance"
  name        = var.security_group_name
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port = var.ports[0]
    to_port   = var.ports[0]
    protocol  = var.protocol
    security_groups = [
      aws_security_group.load_balancer_security_group.id
    ]
  }

  ingress {
    from_port = var.ports[3]
    to_port   = var.ports[3]
    protocol  = var.protocol
    security_groups = [
      aws_security_group.load_balancer_security_group.id
    ]
  }

  egress {
    from_port   = var.ports[4]
    to_port     = var.ports[4]
    protocol    = var.eprotocol
    cidr_blocks = [var.cidr_gateway]
  }

  tags = {
    Name = "application"
  }
}

resource "aws_key_pair" "app_keypair" {
  key_name   = var.keypair_name
  public_key = file(var.keypair_path)
}

# resource "aws_ebs_volume" "ebs_volume" {
#   availability_zone = "${var.aws_region}${var.availability_zones[0]}"
#   size              = var.ebs_volume_size
#   type              = var.ebs_volume_type
#   tags = {
#     Name = var.ebs_volume_name
#   }
# }

data "aws_ami" "latest_ami" {
  most_recent = true
  filter {
    name   = "name"
    values = ["${var.ami_name}-*"]
  }
}

# create IAM instance profile
resource "aws_iam_instance_profile" "profile" {
  name = "ec2-profile"
  role = aws_iam_role.EC2-CSYE6225.name
}

resource "aws_launch_template" "csye_ec2_template" {
  image_id      = data.aws_ami.latest_ami.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.app_keypair.key_name
  name          = "csye_ec2_template"
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.application.id]
  }
  iam_instance_profile {
    name = aws_iam_instance_profile.profile.name
  }
  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_size           = var.ebs_volume_size
      volume_type           = var.ebs_volume_type
      delete_on_termination = true
      encrypted             = true
      kms_key_id            = aws_kms_key.ebs_encryption_key.arn
    }
  }
  user_data = base64encode(<<REALEND
#!/bin/bash
# Update package manager
    sudo apt-get update
    aws acm import-certificate --certificate /home/ec2-user/certificate.pem --private-key /home/ec2-user/private-key.pem --certificate-chain /home/ec2-user/certificate-chain.pem


echo "[Unit]
Description=Webapp Service
After=network.target

[Service]
Environment="DB_HOST=${aws_db_instance.default.address}"
Environment="DB_PORT=${var.DB_PORT}"
Environment="DB_DIALECT=${var.DB_DIALECT}"
Environment="NODE_ENV=${var.NODE_ENV}"
Environment="PORT=${var.PORT}"
Environment="DB_USERNAME=${aws_db_instance.default.username}"
Environment="DB_PASSWORD=${aws_db_instance.default.password}"
Environment="DB=${aws_db_instance.default.db_name}"
Environment="S3=${aws_s3_bucket.private_bucket.bucket}"
Environment="AWS_REGION=${var.aws_region}"

Type=simple
User=ec2-user
WorkingDirectory=/home/ec2-user/webapp
ExecStart=/usr/bin/node listener.js
Restart=on-failure

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/webapp.service
sudo systemctl daemon-reload
sudo systemctl start webapp.service
sudo systemctl enable webapp.service

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/tmp/config.json

REALEND
  )
}

# # Define the launch configuration
# resource "aws_launch_configuration" "csye_ec2_config" {
#   image_id                    = data.aws_ami.latest_ami.id
#   instance_type               = var.instance_type
#   key_name                    = aws_key_pair.app_keypair.key_name
#   security_groups             = [aws_security_group.application.id]
#   name_prefix                 = "aws_launch_config"
#   associate_public_ip_address = true
#   iam_instance_profile        = aws_iam_instance_profile.profile.name

#   # Add SSH key to the instance
#   connection {
#     type        = var.connection_type
#     user        = var.user
#     private_key = file(var.privatekey_path)
#     timeout     = var.ssh_timeout
#     host        = self.public_ip
#   }

#   root_block_device {
#     volume_size           = 50
#     delete_on_termination = true
#   }

#   ebs_block_device {
#     device_name           = "/dev/sdf"
#     volume_size           = var.ebs_volume_size
#     volume_type           = var.ebs_volume_type
#     delete_on_termination = true
#     encrypted             = true
#   }

#   user_data = <<REALEND
# #!/bin/bash
# # Update package manager
#     sudo apt-get update

# echo "[Unit]
# Description=Webapp Service
# After=network.target

# [Service]
# Environment="DB_HOST=${aws_db_instance.default.address}"
# Environment="DB_PORT=${var.DB_PORT}"
# Environment="DB_DIALECT=${var.DB_DIALECT}"
# Environment="NODE_ENV=${var.NODE_ENV}"
# Environment="PORT=${var.PORT}"
# Environment="DB_USERNAME=${aws_db_instance.default.username}"
# Environment="DB_PASSWORD=${aws_db_instance.default.password}"
# Environment="DB=${aws_db_instance.default.db_name}"
# Environment="S3=${aws_s3_bucket.private_bucket.bucket}"
# Environment="AWS_REGION=${var.aws_region}"

# Type=simple
# User=ec2-user
# WorkingDirectory=/home/ec2-user/webapp
# ExecStart=/usr/bin/node listener.js
# Restart=on-failure

# [Install]
# WantedBy=multi-user.target" > /etc/systemd/system/webapp.service
# sudo systemctl daemon-reload
# sudo systemctl start webapp.service
# sudo systemctl enable webapp.service

# sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/tmp/config.json

# REALEND
# }

# Define the auto scaling group
resource "aws_autoscaling_group" "csye_ec2-asg" {
  name             = "csye_ec2-asg"
  default_cooldown = 60
  desired_capacity = 1
  launch_template {
    id      = aws_launch_template.csye_ec2_template.id
    version = "$Latest"
  }
  vpc_zone_identifier = ["${aws_subnet.public[0].id}", "${aws_subnet.public[1].id}", "${aws_subnet.public[2].id}"]
  max_size            = 3
  min_size            = 1
  health_check_type   = "EC2"
  force_delete        = true
  target_group_arns   = [aws_lb_target_group.web.arn]
  tag {
    key                 = "Name"
    value               = "csye_ec2-asg"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "scale_up_policy" {
  name                   = "scale_up_policy"
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.csye_ec2-asg.name

  policy_type        = "SimpleScaling"
  scaling_adjustment = 1
}

resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name          = "scale_up_alarm"
  alarm_description   = "scale_up_alarm"
  evaluation_periods  = "2"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "30"
  statistic           = "Average"
  threshold           = "5"
  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.csye_ec2-asg.name}"
  }
  actions_enabled = true
  alarm_actions   = ["${aws_autoscaling_policy.scale_up_policy.arn}"]
}


resource "aws_autoscaling_policy" "scale_down_policy" {
  name                   = "scale_down_policy"
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.csye_ec2-asg.name

  policy_type        = "SimpleScaling"
  scaling_adjustment = -1
}

resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name          = "scale_down_alarm"
  alarm_description   = "scale_down_alarm"
  evaluation_periods  = "2"
  comparison_operator = "LessThanOrEqualToThreshold"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "3"
  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.csye_ec2-asg.name}"
  }
  actions_enabled = true
  alarm_actions   = ["${aws_autoscaling_policy.scale_down_policy.arn}"]
}

# Launch EC2 instance
# resource "aws_instance" "csye_ec2" {
#   ami                    = data.aws_ami.latest_ami.id
#   instance_type          = var.instance_type
#   subnet_id              = aws_subnet.public[0].id
#   vpc_security_group_ids = [aws_security_group.application.id]
#   tags = {
#     Name = var.ec2_name
#   }
#   key_name = aws_key_pair.app_keypair.key_name

#   associate_public_ip_address = true
#   disable_api_termination     = false

#   root_block_device {
#     volume_size           = 50
#     delete_on_termination = true
#   }

#   # Attach IAM role to instance
#   iam_instance_profile = aws_iam_instance_profile.profile.name

#   # Add SSH key to the instance
#   connection {
#     type        = var.connection_type
#     user        = var.user
#     private_key = file(var.privatekey_path)
#     timeout     = var.ssh_timeout
#     host        = self.public_ip
#   }

#   user_data = <<REALEND
# #!/bin/bash
# # Update package manager
#     sudo apt-get update

#     # Install nginx
#     sudo apt-get install nginx -y

#     # Start nginx
#     sudo systemctl start nginx

#     # Enable nginx to start on boot
#     sudo systemctl enable nginx

#     sudo mkdir /etc/nginx/sites-available
#     sudo mkdir /etc/nginx/sites-enabled

#     sed -i '32 i include /etc/nginx/sites-enabled/*;' /etc/nginx/nginx.conf

#     # Create a new Nginx server block for our Node.js app
#     sudo touch /etc/nginx/sites-available/my-app

#     # Open the file in a text editor
#     sudo nano /etc/nginx/sites-available/my-app

#     cat <<EOF | sudo tee /etc/nginx/sites-available/my-app
# server {
#     listen 80 default_server;
#     listen [::]:80 default_server;

#     server_name ${var.dev_domain} ${var.demo_domain};

#     location / {
#         proxy_pass http://${aws_eip.ec2_eip.public_ip}:5000/;
#         proxy_http_version 1.1;
#         proxy_set_header Upgrade \$http_upgrade;
#         proxy_set_header Connection 'upgrade';
#         proxy_set_header Host \$host;
#         proxy_cache_bypass \$http_upgrade;
#     }
# }
# EOF

#     # Create a symbolic link to enable the new server block
#     sudo ln -s /etc/nginx/sites-available/my-app /etc/nginx/sites-enabled/

#     # Test Nginx configuration
#     sudo nginx -t

#     # Reload Nginx to apply the new configuration
#     sudo systemctl reload nginx
# echo "[Unit]
# Description=Webapp Service
# After=network.target

# [Service]
# Environment="DB_HOST=${aws_db_instance.default.address}"
# Environment="DB_PORT=${var.DB_PORT}"
# Environment="DB_DIALECT=${var.DB_DIALECT}"
# Environment="NODE_ENV=${var.NODE_ENV}"
# Environment="PORT=${var.PORT}"
# Environment="DB_USERNAME=${aws_db_instance.default.username}"
# Environment="DB_PASSWORD=${aws_db_instance.default.password}"
# Environment="DB=${aws_db_instance.default.db_name}"
# Environment="S3=${aws_s3_bucket.private_bucket.bucket}"
# Environment="AWS_REGION=${var.aws_region}"

# Type=simple
# User=ec2-user
# WorkingDirectory=/home/ec2-user/webapp
# ExecStart=/usr/bin/node listener.js
# Restart=on-failure

# [Install]
# WantedBy=multi-user.target" > /etc/systemd/system/webapp.service
# sudo systemctl daemon-reload
# sudo systemctl start webapp.service
# sudo systemctl enable webapp.service

# sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/tmp/config.json

# REALEND
# }

# resource "aws_volume_attachment" "ebsAttach" {

#   device_name = var.device_name
#   volume_id   = aws_ebs_volume.ebs_volume.id
#   instance_id = aws_instance.csye_ec2.id

# }

# # Allocate Elastic IP
# resource "aws_eip" "ec2_eip" {
#   vpc = true
# }

# # Associate Elastic IP with EC2 instance
# resource "aws_eip_association" "ec2_eip_assoc" {
#   instance_id   = aws_instance.csye_ec2.id
#   allocation_id = aws_eip.ec2_eip.id
# }

resource "random_string" "random" {
  length  = 8
  special = false
  upper   = false
}

# Create S3 bucket with a random name
resource "aws_s3_bucket" "private_bucket" {
  bucket        = "${var.bucket_name}${random_string.random.result}${var.aws_profile}"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "example_bucket_acl" {
  bucket = aws_s3_bucket.private_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.private_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "access_bucket" {
  bucket = aws_s3_bucket.private_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Configure S3 bucket lifecycle policy to delete objects
resource "aws_s3_bucket_lifecycle_configuration" "private_bucket_lifecycle" {
  bucket = aws_s3_bucket.private_bucket.id
  rule {
    id     = "delete-objects"
    status = "Enabled"
    prefix = ""
    expiration {
      days = 30
    }
  }

  rule {
    id     = "transition-to-standard-ia"
    status = "Enabled"
    prefix = ""
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

# Configure S3 bucket versioning
resource "aws_s3_bucket_versioning" "private_bucket_versioning" {
  bucket = aws_s3_bucket.private_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Create IAM policy for S3 access
resource "aws_iam_policy" "WebAppS3" {
  name        = "WebAppS3"
  description = "Allows EC2 instances to access S3 buckets"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:DeleteObject",
          "s3:ListBucket"

        ]
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.private_bucket.bucket}/*",
          "arn:aws:s3:::${aws_s3_bucket.private_bucket.bucket}"
        ]
      }
    ]
  })
}

# Create IAM policy for Cloudwatch
resource "aws_iam_policy" "WebAppCloudWatch" {
  name        = "WebAppCloudWatch"
  description = "Allows EC2 instances to access CloudWatch"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "cloudwatch:PutMetricData",
            "ec2:DescribeTags",
            "logs:PutLogEvents",
            "logs:DescribeLogStreams",
            "logs:DescribeLogGroups",
            "logs:CreateLogStream",
            "logs:CreateLogGroup"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ssm:GetParameter",
            "ssm:PutParameter"
          ],
          "Resource" : "arn:aws:ssm:*:*:parameter/AmazonCloudWatch-*"
        }
      ]
    }
  )
}

# Create IAM role for EC2 instance
resource "aws_iam_role" "EC2-CSYE6225" {
  name = "EC2-CSYE6225"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach S3 access policy to IAM role
resource "aws_iam_role_policy_attachment" "s3_access_policy_attachment" {
  policy_arn = aws_iam_policy.WebAppS3.arn
  role       = aws_iam_role.EC2-CSYE6225.name
}

# Attach CloudWatch access policy to IAM role
resource "aws_iam_role_policy_attachment" "cw_access_policy_attachment" {
  policy_arn = aws_iam_policy.WebAppCloudWatch.arn
  role       = aws_iam_role.EC2-CSYE6225.name
}

resource "aws_db_instance" "default" {
  allocated_storage       = 10
  db_name                 = var.DB_USERNAME
  engine                  = var.DB_DIALECT
  instance_class          = var.rds_instance
  identifier              = var.DB_USERNAME
  username                = var.DB_USERNAME
  password                = var.DB_PASSWORD
  multi_az                = false
  publicly_accessible     = false
  parameter_group_name    = aws_db_parameter_group.my_parameter_group.id
  skip_final_snapshot     = true
  apply_immediately       = true
  backup_retention_period = 0
  storage_encrypted       = true
  kms_key_id              = aws_kms_key.rds_encryption_key.arn
  vpc_security_group_ids = [
    aws_security_group.database_security_group.id
  ]

  db_subnet_group_name = aws_db_subnet_group.my_subnet_group.name

  tags = {
    Name = var.DB_USERNAME
  }
}

data "aws_db_instance" "default" {
  db_instance_identifier = aws_db_instance.default.id
}

resource "aws_db_parameter_group" "my_parameter_group" {
  name   = "my-parameter-group"
  family = "mysql8.0"

  parameter {
    name  = "max_allowed_packet"
    value = "67108864"
  }
}

resource "aws_db_subnet_group" "my_subnet_group" {
  name        = "my-subnet-group"
  description = "My subnet group for RDS instance"

  subnet_ids = [aws_subnet.private[0].id, aws_subnet.private[1].id, aws_subnet.private[2].id]
}

resource "aws_security_group" "database_security_group" {
  description = "Security group for RDS instances"
  name        = "database"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    security_groups = [
      aws_security_group.application.id
    ]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = {
    Name = "database"
  }
}

data "aws_route53_zone" "example_zone" {
  name = var.aws_profile == "dev" ? var.dev_domain : var.demo_domain
}

resource "aws_route53_record" "example_record" {
  zone_id = data.aws_route53_zone.example_zone.id
  name    = var.aws_profile == "dev" ? var.dev_domain : var.demo_domain
  type    = "A"

  alias {
    name                   = aws_lb.web.dns_name
    zone_id                = aws_lb.web.zone_id
    evaluate_target_health = true
  }
}

resource "aws_security_group" "load_balancer_security_group" {

  description = "Security group for load balancer"
  name        = "load_balancer"
  vpc_id      = aws_vpc.main.id

  # ingress {
  #   from_port   = var.ports[1]
  #   to_port     = var.ports[1]
  #   protocol    = var.protocol
  #   cidr_blocks = [var.cidr_gateway]
  # }

  ingress {
    from_port   = var.ports[2]
    to_port     = var.ports[2]
    protocol    = var.protocol
    cidr_blocks = [var.cidr_gateway]
  }

  egress {
    from_port   = var.ports[4]
    to_port     = var.ports[4]
    protocol    = var.eprotocol
    cidr_blocks = [var.cidr_gateway]
  }

  tags = {
    Name = "load balancer"
  }

}

resource "aws_lb" "web" {
  name               = "my-web-app-lb"
  internal           = false
  load_balancer_type = "application"

  subnets         = [aws_subnet.public[0].id, aws_subnet.public[1].id, aws_subnet.public[2].id]
  security_groups = [aws_security_group.load_balancer_security_group.id]
}

resource "aws_lb_listener" "web-dev" {
  count             = var.aws_profile == "dev" ? 1 : 0
  load_balancer_arn = aws_lb.web.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = data.aws_acm_certificate.dev[0].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

data "aws_acm_certificate" "my_cert" {
  count    = var.aws_profile == "demo" ? 1 : 0
  domain   = "prod.prudhvinakkina.me"
  statuses = ["ISSUED"]
}

resource "aws_lb_listener" "web-demo" {
  count             = var.aws_profile == "demo" ? 1 : 0
  load_balancer_arn = aws_lb.web.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = data.aws_acm_certificate.my_cert[0].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_lb_target_group" "web" {
  name        = "my-web-app-target-group"
  port        = 5000
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id

  health_check {
    path                = "/healthz"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }
}

resource "aws_kms_key" "ebs_encryption_key" {
  description             = "Customer managed key for EBS encryption"
  deletion_window_in_days = 7
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "kms:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow access for Key Administrators"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ],
        Resource = "*"
      },
      {
        Sid    = "Enable EBS Encryption"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_key" "rds_encryption_key" {
  description             = "Customer managed key for RDS encryption"
  deletion_window_in_days = 7
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "kms:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow access for Key Administrators"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ],
        Resource = "*"
      },
      {
        Sid    = "Enable RDS Encryption"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

data "aws_acm_certificate" "dev" {
  count    = var.aws_profile == "dev" ? 1 : 0
  domain   = "dev.prudhvinakkina.me"
  statuses = ["ISSUED"]
}

# resource "aws_acm_certificate_validation" "dev" {
#   count             = try(var.aws_profile == "dev" ? 1 : 0, 0)
#   certificate_arn   = aws_acm_certificate.dev[0].arn

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_lb_listener_certificate" "example" {
#   count           = try(var.aws_profile == "dev" ? 1 : 0, 0)
#   listener_arn    = aws_lb_listener.web.arn
#   certificate_arn = aws_acm_certificate.dev[0].arn
# }

# resource "aws_route53_record" "ssl_cname" {
#   count   = try(var.aws_profile == "dev" ? 1 : 0, 0)
#   zone_id = data.aws_route53_zone.example_zone.id
#   name    = "dev"
#   type    = "CNAME"
#   ttl     = "300"

#   records = [
#     "${aws_lb.web.dns_name}",
#   ]
# }

