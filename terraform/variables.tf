# VARIABLES FOR MAIN
variable "region" {
  default = "eu-west-1"
}

variable "ami_app" {
  default = "ami-0489ce290f126c3e4"
}

variable "ami_db" {
  default = "ami-03646b6976790491d"
}

variable "ami_jenkins" {
  default = "ami-05d324167a55228fe"
}

variable "ami_ubuntu" {
  default = "ami-0dc8d444ee2a42d8a"
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
