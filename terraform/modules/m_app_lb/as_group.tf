# provides EC2 launch configuration resource
resource "aws_launch_configuration" "app_launch_conf" {
    name = "eng74-fp-launch_conf"
    image_id = var.app_ami
    instance_type = var.instance_type
    security_groups = [var.app_sg_id]
    associate_public_ip_address = true
    key_name = var.key_pair_name

    user_data = <<-EOF
    #!/bin/bash
    sudo hostname autoscale_app
    sudo sed -i "16ihostname=autoscale_app" /etc/netdata/netdata.conf
    sudo service netdata restart
    sudo netdata-claim.sh -token=7fviTnD7DC68hnpCA8ON8RvBZ4dkWOzr5WeV9j6Z7j9iV0YAAK0zpltwpWr6Ihil7pUaDjXFrGZAktECA19365Ukfded3tBNYOniX4jLLstdaMwVMw4KG4zt4Q9LBbPs7MSso28 -rooms=d1dd6ee9-2feb-4b4d-85b1-55808fceead0 -url=https://app.netdata.cloud -id=$(uuidgen)
  EOF
}


resource "aws_autoscaling_group" "app_as_group" {
    name = "eng74-fp-app_as_group"
    depends_on = [aws_launch_configuration.app_launch_conf]
    launch_configuration = aws_launch_configuration.app_launch_conf.name
    min_size = 2
    desired_capacity = 3
    max_size = 10
    vpc_zone_identifier = [var.public_subnet_id]
    target_group_arns = [aws_lb_target_group.app_lb_target_group.arn]

    lifecycle {
      create_before_destroy = true
    }

    tag {
      key = "Name"
      value = "eng74-fp-as_group-app"
      propagate_at_launch = true
    }
}

# # attach austoscaling policy
# resource "aws_autoscaling_policy" "as_group_policy_simple" {
#   name = "eng74-fp-as_group_policy-simple"
#   autoscaling_group_name = aws_autoscaling_group.app_as_group.name
#   adjustment_type = "ChangeInCapacity"
#   target_tracking_configuration {
#     predefined_metric_specification {
#         predefined_metric_type = "ASGAverageCPUUtilization"
#     }
#     target_value = 80
#   }
# }


# attach austoscaling policy
resource "aws_autoscaling_policy" "as_group_policy" {
  name = "eng74-fp-as_group_policy-cpu"
  autoscaling_group_name = aws_autoscaling_group.app_as_group.name
  policy_type = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
        predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 80
  }
}
