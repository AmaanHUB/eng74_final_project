# AMIs

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
