# VARIABLES FOR EC2 MODULE

variable "ami_id" {
    description = "AMI for EC2 instance"
}

variable "subnet_id" {}

variable "instance_type" {}

variable "security_group_id" {}

variable "aws_key_name" {}

variable "name_tag" {}

variable "associate_pub_ip" {
    default = true
}