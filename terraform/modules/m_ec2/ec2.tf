
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

  provisioner "file" {
    source      = "${path.module}/${var.data_file}"
    destination = "/home/ubuntu/${var.data_file}"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      password    = ""
      private_key = file(var.aws_key_path)
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "export APP_IP=${tostring(var.app_ip)}",
      "bash /home/ubuntu/${var.data_file}"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      password    = ""
      private_key = file(var.aws_key_path)
      host        = self.public_ip
    }
  }

}
