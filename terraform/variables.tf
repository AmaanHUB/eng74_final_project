# VARIABLES FOR MAIN
variable "region" {
  default = "eu-west-1"
}

variable "ami_app" {
  default = "ami-0c2736f128eb22c2d"
}

variable "ami_db" {
  default = "ami-0c2736f128eb22c2d"
}

variable "ami_jenkins" {
  default = "ami-026fb5c9d1d7c3fc7"
}

variable "ami_ubuntu" {
  default = "ami-0c2736f128eb22c2d"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "aws_key_name" {
  default = "eng74_fp_aws_key"
}

variable "aws_key_path" {
  default = "~/.ssh/eng74_fp_aws_key.pem"
}

variable "extra_user_ip" {
  default = "84.69.102.61"
}
