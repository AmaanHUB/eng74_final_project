# OUTPUTS FROM VPC MODULE

output "vpc_id" {
    value = aws_vpc.main.id
}

output "controller_subnet_id" {
    value = aws_subnet.controller_subnet.id
}

output "public_subnet_id" {
    value = aws_subnet.public_subnet.id
}

output "private_subnet_id" {
    value = aws_subnet.private_subnet.id
}