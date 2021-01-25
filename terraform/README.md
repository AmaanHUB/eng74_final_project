## Building the Infrastructure with Terraform

### What is Terraform?

[Terraform](https://www.terraform.io/) is an extremely powerful orchestration tool using Infrastructure as Code (IaC) to manage and organise components of infrastructure. Using declarative files we can create an entire description of our infrastructure and  run three commands to build it all in a matter of minutes.
```bash
terraform init
terraform plan
terraform apply
```
### Virtual Private Cloud Module

For this project we were tasked with building a Virtual Private Cloud (VPC) in AWS to host the web application. The components that would be required for the VPC include:
- ``aws_vpc``: To initialise the VPC
- ``aws_internet_gateway``: Create an Internet Gateway (IGW) to allow our EC2 instances to communicate with the internet, a vital step for hosting a website
- ``aws_route_table``: Contains a set of rules (routes) that are used to determine where network traffic from a subnet/gateway is directed
    - ``aws_route_table_association``: after creating a public route table that enables traffic from the IGW, we can specify which subnets to associate to the IGW
- ``aws_subnet``: For this project, we created three subnets
    - ``Public``: This is where the web application would be hosted and would have internet access open to all
    - ``Private``: A subnet with no internet access, added in case of a potential increment of utilising a database which we would want to restrict access to
    - ``Controller``: This subnet hosted the Bastion server (which had SSH access to instances in both other subnets), as well as the instance that hosted Jenkins
- ``aws_network_acl``: The Network Access Control List act as a firewall for controlling traffic in and out of a subnet

All of these components were contained in the VPC module (``modules/m_vpc``) which only required two input variables for the IP addresses of 2 members of the team who would have SSH access
```
module "vpc" {
  source = "./modules/m_vpc"

  my_ip         = module.myip.address
  extra_user_ip = var.extra_user_ip
}
```
Where the ``myip`` module utilised an external module to automatically return the local user's public IP address instead of having to hardcode it

**OUTPUTS**

The VPC module outputs:
- ``vpc_id``: The unique ID of the AWS VPC
- ``controller_subnet_id``: The unique ID of the Controller subnet
- ``public_subnet_id``: The unique ID of the Public subnet
- ``private_subnet_id``: The unique ID of the Private subnet

### Security Group Module

In this module (``modules/m_sg``) we specify the security group rules to be used by each type of EC2 instance: app, bastion, and Jenkins. A temporary placeholder for the database security group was made as well.

- ``aws_security_group``: Specify the ingress and egress rules for each type

The module only requires the ``vpc_id``, and two user IP addresses to be specified
```
module "sg" {
  source = "./modules/m_sg"

  vpc_id        = module.vpc.vpc_id
  my_ip         = module.myip.address
  extra_user_ip = var.extra_user_ip
}
```

**OUTPUTS**

The security group module outputs: 
- ``bastion_sg_id``: The unique ID of the security group to be used by the bastion instance
- ``jenkins_sg_id``: The unique ID of the security group to be used by the jenkins instance
- ``app_sg_id``: The unique ID of the security group to be used by the app instance
- ``db_sg_id``: The unique ID of the security group to be used by the database instance

### EC2 Instance Module

This module (``modules/m_ec2``) is where we create the EC2 instance. Everything has been abstracted so that we can reuse this module to create all 4 types of instances outlined above. 

- ``aws_instance``: Create and configure the EC2 instance

This module has several arguments that are required to be passed
- ``ami_id``: The Amazon Machine Image ID that will have been prepared using Ansible and Packer
- ``subnet_id``: Specify which of the three subnets to create the instance in
- ``instance_type``: Specify the instance type 
- ``security_group_id``: The ID of the security group to assign (outputted from the security group module)
- ``aws_key_name``: The name of the private AWS key to be assigned to the instance
- ``aws_key_path``: The path to the AWS key file, as the key was required to SSH into the instance and run a bash script
- ``name_tag``: Name to assign to the instance on AWS
- ``hostname``: Name to assign to the instance on Netdata
```
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
```
All instances have a default bash script to execute to claim the node to Netdata, except the Jenkins instance which required an extra command to be carried out to edit the Jenkins config file, and so for the Jenkins instance an extra two variables, ``data_file`` and ``app_ip``, was specified.

**OUTPUTS**

The EC2 module outputs:
- ``ec2_public_ip``: The public IP of the EC2 instance
- ``ec2_private_ip``: The private IP of the EC2 instance

### Load Balancer and Auto Scaling Module

This module specifies the configuration for the Load Balancer and Auto-Scaling Group as the next increment to maintain high availability of our web application.

This involved several components
- ``aws_lb``: Initialise the load balancer and specify what type it is (``network``)
- ``aws_lb_target_group``: Used to route requests to one or more registered targets, used in conjuction with a listener rule
- ``aws_lb_listener``: Configure a listener for port 80 to forward all traffic to the previously created target group
- ``aws_launch_configuration``: Specify the configuration of the EC2 instance to launch, as well as execute commands to claim the node to Netdata
- ``aws_autoscaling_group``: The autoscaling group with minimum/maximum/desired number of EC2 instances to contain
- ``aws_autoscaling_policy``: Specify the policy for the autoscaling group to use when determining when to scale out/in (e.g. average CPU utilisation)

The module requires several variables to be passed, mainly used for the launch configuration
```
module "app_lb" {
  source = "./modules/m_app_lb"

  app_ami          = var.ami_lb
  instance_type    = var.instance_type
  app_sg_id        = module.sg.app_sg_id
  public_subnet_id = module.vpc.public_subnet_id
  vpc_id           = module.vpc.vpc_id
  key_pair_name = var.aws_key_name
}
```

**OUTPUTS**

The Load Balancer module does not require any outputs.