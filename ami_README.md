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

* Finally, Jenkins is installed and `jenkins.service` is enabled.
```yaml
    - name: Installing Jenkins and start
      apt:
        name: jenkins
        state: present
        force: yes
```

### Standard Instance (standard_instance.yaml)

This is a base image on which the app will run during the deployment stage, as well as being a standard base image on which the Jenkins (and others) will build on top of.
* The docker dependencies as well as the docker key as well
