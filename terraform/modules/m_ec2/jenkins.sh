#!/bin/bash
sudo hostname $HOSTNAME
sudo sed -i "16ihostname=$HOSTNAME" /etc/netdata/netdata.conf
sudo service netdata restart
sudo netdata-claim.sh -token=7fviTnD7DC68hnpCA8ON8RvBZ4dkWOzr5WeV9j6Z7j9iV0YAAK0zpltwpWr6Ihil7pUaDjXFrGZAktECA19365Ukfded3tBNYOniX4jLLstdaMwVMw4KG4zt4Q9LBbPs7MSso28 -rooms=d1dd6ee9-2feb-4b4d-85b1-55808fceead0 -url=https://app.netdata.cloud -id=$(uuidgen)
sudo sed -i "s/ubuntu@74.11.1.21/ubuntu@$APP_IP/" /var/lib/jenkins/jobs/CDE-Deployment/config.xml