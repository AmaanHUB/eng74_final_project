# Engineering 74: Final Project - CI/CD, Infrastructure Configuration and Orchestration

## Contents

1. [Introduction](#Introduction)
2. [CI/CD Pipeline](#CI/CD-Pipeline)
3. [Configuration Management](#Configuration-Management)
4. [Cloud Infrastructure](#Cloud-Infrastructure)
5. [Cloud Monitoring](#Cloud-Monitoring)

## Introduction

This repository contains information about the CI/CD pipeline and infrastructure configuration and orchestration, all used to automatically test and host the web application used in the final project of the Engineering 74 DevOps team.

The members of the team include:

- [Maciej Sokol](https://github.com/MattSokol79): Jenkins CI/CD
- [Amaan Hashmi-Ubhi](https://github.com/AmaanHUB): Configuration Management
- [Leo Waltmann](https://github.com/ldaijiw): Cloud Infrastructure
- [Hubert Swic](https://github.com/deviljin112): Cloud Monitoring

For more about the work of the other teams of the project, check out:
- [Front End Team](https://github.com/jatkin-wasti/final-project-front-end)
- [Back End Team](https://github.com/samturton2/Webscraper-FinalProject)

[Return to top](#Contents)

# CI/CD Pipeline

[Return to top](#Contents)

# Configuration Management

## Ansible Provisioning

To provision an image with all the relevant software and configurations. Ansible was used to create playbooks that were used in super-playbooks, which allowed the reuse of certain ones.

### Netdata Setup (netdata_setup.yaml)

This playbook is used in both the setup of Jenkins and the Standard Instances, so that they all may be monitored. The tasks within it are shown below:
* The task below pulls the installation bash script from the relevant url, puts it in the `/root/` directory (since this playbook is done as the root user), and sets the permissions as executable
```yaml
    - name: get the file for installation
      get_url:
        url: https://my-netdata.io/kickstart.sh
        dest: /root/
        mode: 'u+x,g+x'
```
* The task below runs the bash script (with arguments so that one doesn't need to manually press enter at certain points as one normally would) to install Netdata on the instance. It does not run it, as this is done when the instance is started using Terraform.
```yaml
    - name: install the file
      shell: bash /root/kickstart.sh all --non-interactive
```

### Standard Instance (standard_instance.yaml)

This is a base image on which the everything is built off, from the app to Jenkins.
* The  dependencies to install docker as installed
```yaml
    - name: Install the docker dependencies
      apt:
        pkg:
          - apt-transport-https
          - ca-certificates
          - curl
          - gnupg
          - software-properties-common
```

* The key and repo for docker are added, as well as an update of the cache so that the new source will be read and docker can be installed
```yaml

    - name: Add the docker key
      apt_key:
        url: https://download.docker.com/linux/ubuntu/gpg
        state: present

    - name: Adding the docker repo
      apt_repository:
        repo: deb https://download.docker.com/linux/ubuntu bionic stable
      notify: update_cache
```

* Install docker and the relevant programs
```yaml

    - name: Install docker and related software
      apt:
        pkg:
          - docker-ce
          - docker-ce-cli
          - containerd.io
```

* Install docker-compose in case that is needed
```yaml

    - name: Get docker-compose files and install locally (as this is how it is done on Ubuntu)
      get_url:
        url: https://github.com/docker/compose/releases/download/1.27.4/docker-compose-Linux-x86_64
        dest: /usr/local/bin/docker-compose
        mode: 'u+x,g+x'
```

* Finally, set the Ubuntu default user in the docker group
```yaml
    - name: Add ubuntu user to the docker group
      user:
        name: ubuntu
        groups: 'docker'
        append: yes
```

### Jenkins (jenkins.yaml)

This playbook is specific to installing the dependencies of Jenkins and Jenkins itself on a blank Ubuntu instance. This is intended to be used to set up Jenkins in the first place and also be used in disaster recovery scenarios whereby the Jenkins instance and it's subsequent fully-loaded AMI are lost.

* Firstly the dependencies for Jenkins are installed as well as `python3-pip` since this is going to be used in the CI stage when we test the actual code before integrating it into the main branch.
```yaml
    - name: Install dependencies
      apt:
        pkg:
          - openjdk-11-jdk
          - python3
          - python3-pip
```

* The Jenkins key, which will be used installing Jenkins and confirming that it is actually Jenkins is added to the local `apt-key` repository.
```yaml
    - name: Get the Jenkins key from the official servers
      apt_key:
        url: https://pkg.jenkins.io/debian/jenkins.io.key
        state: present
```

* The Jenkins repository is added to the source list, as well as manually updating `apt` to confirm that this new source list will be read.
```yaml
    - name: Adding the Jenkins deb repo to the source list
      apt_repository:
        repo: deb http://pkg.jenkins-ci.org/debian-stable binary/
        state: present
        filename: "jenkins"
        update_cache: yes

    - name: Manually update_cache
      apt:
        update_cache: yes
```

* Jenkins is installed and `jenkins.service` is enabled.
```yaml
    - name: Installing Jenkins and start
      apt:
        name: jenkins
        state: present
        force: yes
```

* The default user created by Jenkins (jenkins) is assigned to the `docker` group so that it may have easy access to docker's capabilities
```yaml
    - name: Add jenkins user to the docker group
      user:
        name: jenkins
        groups: 'docker'
        append: yes

    - name: Restart docker.service
      service:
        name: docker
        state: restarted
```

### Cron (docker_cron.yaml)

* This is a small playbook to create a small cron script that will pull the latest version of the app from DockerHub and run it
```yaml
    - name: Create a cron script that runs a bash script
      cron:
        name: Run docker script
        minute: "*/10"
        job:  "docker stop App; docker system prune -af; docker pull amaanhub/eng74_final_project; docker run -d --name App -p 80:5000 amaanhub/eng74_final_project"
```

### Super Playbooks

* Super playbooks are an amalgamation of smaller playbooks that contains certain tasks, so that they can be tailored to a certain type of image that will be made. Additionally, it allows the reuse of code rather than having to create it for each individial image that will be created with Packer.

#### main_standard.yaml

* This is a playbook that would create the standard EC2 instance which most, if not all, the other EC2 instances will be based upon.

```yaml
- name: Netdata setup
  import_playbook: netdata_setup.yaml

- name: EC2 instance setup
  import_playbook: standard_instance.yaml
```

#### main_jenkins.yaml

* As the name suggests, this 'super playbook' is used to create and provision an image in which Jenkins will run, with all the dependencies for the specific tasks we have assigned to it (.i.e. build docker images)
```yaml
- name: Netdata setup
  import_playbook: netdata_setup.yaml

- name: Install docker etc
  import_playbook: standard_instance.yaml

- name: EC2 instance setup
  import_playbook: jenkins.yaml
```

#### main_load_balancing.yaml

* The image that this helps create is used within load balancing on AWS, and given that we wanted an easy way for these images to update, we added a cron job to upate it regularly (`docker_cron.yaml`). For all intents and purposes, it is exactly the same as `main_standard.yaml` except for the cron job.

```yaml
- name: Netdata setup
  import_playbook: netdata_setup.yaml

- name: EC2 instance setup
  import_playbook: standard_instance.yaml

- name: Cron job for docker
  import_playbook: docker_cron.yaml
```

## Packer Image Creation

All the packer creation files here have the same format (`jenkins.json`, `load_balancing.json`, `standard.json`).

* The format is of json, with `variables` containing the file_location (which is probably the only part that one would change, depending on where they have cloned the directory, with the `aws_access_key` and `aws_secret_key` reading from the terminal ![environment variables](https://wiki.archlinux.org/index.php/Environment_variables)
```json
{
	"variables": {
		"aws_access_key": "{{ env `AWS_ACCESS_KEY` }}",
		"aws_secret_key": "{{ env `AWS_SECRET_KEY` }}",
		"file_location": "/file/path/here"
	},
```

* Within the builders, section everything is relatively self-explanatory, with the only changes one would realistically make to this exact project are the `instance_type` and `ami_name`.
```json
	"builders": [
		{
			"type": "amazon-ebs",
			"access_key": "{{user `aws_access_key`}}",
			"secret_key": "{{user `aws_secret_key`}}",
			"region": "eu-west-1",
			"source_ami_filter": {
				"filters": {
					"virtualization-type": "hvm",
					"name": "ubuntu/images/*ubuntu-bionic-18.04-amd64-server-*",
					"root-device-type": "ebs"
				},
				"owners": [
					"099720109477"
				],
				"most_recent": true
			},
			"instance_type": "t2.micro",
			"ssh_username": "ubuntu",
			"ami_name": "eng74_jenkins_final"
		}
	],
```

* Within this section, Packer calls ansible and the relevant playbook file (one of the `main_*.yaml` super playbooks), with no changes needed to be made, since the file location has been called at the beginning.
```json
	"provisioners": [
		{
			"type": "ansible",
			"playbook_file": "{{user `file_location` }}/provisioning/file_name.yaml"
		}
	]
}
```

[Return to top](#Contents)

# Cloud Infrastructure

### Building the Infrastructure with Terraform

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

[Return to top](#Contents)

# Cloud Monitoring

[Return to top](#Contents)