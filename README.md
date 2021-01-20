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
* The task below runs the bash script (with arguments so that one doesn't need to manually press enter at certain points as one normally would) to install Netdata on the instance.
```yaml
    - name: install the file
      shell: bash /root/kickstart.sh all --non-interactive
```
