# create security group allowing access from bastion
resource "aws_security_group" "db_sg"{
	name = "eng74-fp-db_sg"
	description = "Allow public access for db instance"
	vpc_id = var.vpc_id

	ingress {
		description = "SSH from bastion"
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = [aws_security_group.bastion_sg.id]
	}

	egress {
		description = "All traffic out"
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}

	tags = {
		Name = "eng74-fp-db_sg"
	}
}
