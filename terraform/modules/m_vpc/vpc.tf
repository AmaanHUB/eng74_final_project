# create VPC
resource "aws_vpc" "main" {
	cidr_block = "74.11.0.0/16"
	
	tags = {
		Name = "eng74-fp-vpc"
	}
}


# create IGW
resource "aws_internet_gateway" "main_igw" {
	vpc_id = aws_vpc.main.id
	tags = {
		Name = "eng74-fp-igw"
	}
}
