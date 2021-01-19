
# create aws ec2 instance
resource "aws_instance" "ec2_instance" {
  ami                         = var.ami_id
  subnet_id                   = var.subnet_id
  instance_type               = var.instance_type
  key_name                    = var.aws_key_name
  associate_public_ip_address = var.associate_pub_ip
  vpc_security_group_ids      = [var.security_group_id]
  tags = {
    Name = var.name_tag
  }
  user_data = <<-EOF
    #!/bin/bash
    sudo netdata-claim.sh -token=7fviTnD7DC68hnpCA8ON8RvBZ4dkWOzr5WeV9j6Z7j9iV0YAAK0zpltwpWr6Ihil7pUaDjXFrGZAktECA19365Ukfded3tBNYOniX4jLLstdaMwVMw4KG4zt4Q9LBbPs7MSso28 -rooms=d1dd6ee9-2feb-4b4d-85b1-55808fceead0 -url=https://app.netdata.cloud"
  EOF
}
