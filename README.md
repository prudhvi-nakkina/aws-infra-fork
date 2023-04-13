# Assignment - 9

## Goal

### The goal of this assignment is to use Terraform, which is an Infrastructure As Code software to automate Infrastructure on AWS Cloud

## Features

- As a developer, I can Create Virtual Private Cloud (VPC) on AWS
- As a developer, I can Create subnets in VPC
- As a developer, I can Create an Internet Gateway and attach the Internet Gateway to the VPC
- As a developer, I can Create a public route table and Attach all public subnets created to the route table
- As a developer, I can Create a private route table and Attach all private subnets created to the route table
- As a developer, I can Create a public route in the public route table

## Features - Assignment-4

- As a developer, I can launch an EC2 instance by providing ami id

## Features - Assignment-5

- As a developer, I can launch an EC2 instance by providing user_data
- As a developer, I can launch an RDS instance by providing security group and parameter group
- As a developer, I can launch S3 instance
- As a developer, I can create a new policy to allow ec2 instance communicate with S3

## Features - Assignment-6

- As a developer, I can route the traffic to port 80 by using NGINX
- As a developer, I can create an A record for the EC2 instance IP address and use domain name to access the server

## Assignment-7 features

- As a user, I want all application log data to be available in CloudWatch.
- As a user, I want metrics on API usage available in CloudWatch.
- As a developer, I can log metrics using statsd

## Assignment-8 features

- As a developer, I can implement auto scaling of ec2 instances based on CPU Utilization
- As a developer, I can implement load balancing using application load balancer

## Assignment-8 features

- As a developer, I can implement continuous delivery by refreshing launch template
- As a developer, I can implement ssl encryption

## Requirements

- Terraform
- Linux

## Steps to run the project

- clone the repository
- run terraform init
- run terraform plan
- run terraform apply
- check AWS Console to verify

## import certificate

aws acm import-certificate --certificate fileb:///mnt/c/prod_prudhvinakkina_me/Certificate.crt --private-key fileb:///mnt/c/prod_prudhvinakkina_me/PrivateKey.pem --certificate-chain fileb:///mnt/c/prod_prudhvinakkina_me/CertificateChain.pem
