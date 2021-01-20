# create network load balancer
resource "aws_lb" "app_lb" {
    name = "eng74-fp-applb"
    load_balancer_type = "network"
    subnets = [var.public_subnet_id]

    tags = {
        Environment = "Production"
    }
}

# target group
resource "aws_lb_target_group" "app_lb_target_group" {
    name = "eng74-fp-targetgroup"
    port = "80"
    protocol = "TCP"
    vpc_id = var.vpc_id

    tags = {
        Name = "eng74-fp-target_group"
    }
}
# load balancer listener
resource "aws_lb_listener" "load_balancer_listener" {
    load_balancer_arn = aws_lb.app_lb.arn
    port = "80"
    protocol = "TCP"

    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.app_lb_target_group.arn
    }
}
