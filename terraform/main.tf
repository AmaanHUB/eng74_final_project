# Cloud provider required, in this case using AWS
provider "aws" {
  region = "eu-west-1"
}

module "myip" {
  source  = "4ops/myip/http"
  version = "1.0.0"
}

module "vpc" {
  source = "./modules/m_vpc"

  my_ip         = module.myip.address
  extra_user_ip = var.extra_user_ip
}


# create security groups
module "sg" {
  source = "./modules/m_sg"

  vpc_id        = module.vpc.vpc_id
  my_ip         = module.myip.address
  extra_user_ip = var.extra_user_ip
}

# create bastion instance
module "bastion" {
  source = "./modules/m_ec2"

  ami_id            = var.ami_ubuntu
  subnet_id         = module.vpc.controller_subnet_id
  instance_type     = var.instance_type
  security_group_id = module.sg.bastion_sg_id
  aws_key_name      = var.aws_key_name
  name_tag          = "eng74-fp-bastion"
  aws_key_path      = var.aws_key_path
  hostname = "bastion"
}

# create app instance
module "app" {
  source = "./modules/m_ec2"

  ami_id            = var.ami_app
  subnet_id         = module.vpc.public_subnet_id
  instance_type     = var.instance_type
  security_group_id = module.sg.app_sg_id
  aws_key_name      = var.aws_key_name
  name_tag          = "eng74-fp-preproduction_app"
  aws_key_path      = var.aws_key_path
  hostname = "preproduction_app"
}

# create jenkins instance
module "jenkins" {
  source = "./modules/m_ec2"

  ami_id            = var.ami_jenkins
  subnet_id         = module.vpc.controller_subnet_id
  instance_type     = "t2.medium"
  security_group_id = module.sg.jenkins_sg_id
  aws_key_name      = var.aws_key_name
  name_tag          = "eng74-fp-jenkins"
  app_ip            = module.app.ec2_private_ip
  data_file         = var.jenkins_file
  aws_key_path      = var.aws_key_path
  hostname = "jenkins"
}

module "app_lb" {
  source = "./modules/m_app_lb"

  app_ami          = var.ami_lb
  instance_type    = var.instance_type
  app_sg_id        = module.sg.app_sg_id
  public_subnet_id = module.vpc.public_subnet_id
  vpc_id           = module.vpc.vpc_id
  key_pair_name = var.aws_key_name
}
