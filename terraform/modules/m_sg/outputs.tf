# OUTPUTS FROM SECURITY GROUP MODULE

output "bastion_sg_id" {
    value = aws_security_group.bastion_sg.id
}


output "jenkins_sg_id" {
    value = aws_security_group.jenkins_sg.id
}


output "app_sg_id" {
    value = aws_security_group.app_sg.id
}


output "db_sg_id" {
    value = aws_security_group.db_sg.id
}