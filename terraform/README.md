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

The VPC module outputs
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

The security group module outputs 
- ``bastion_sg_id``: The unique ID of the security group to be used by the bastion instance
- ``jenkins_sg_id``: The unique ID of the security group to be used by the jenkins instance
- ``app_sg_id``: The unique ID of the security group to be used by the app instance
- ``db_sg_id``: The unique ID of the security group to be used by the database instance