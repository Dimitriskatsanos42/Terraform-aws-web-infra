############################################
# EC2 Module
# Launch Template + Auto Scaling Group
# για τα web servers πίσω από το ALB
############################################

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_security_group" "web" {
  name_prefix = "${var.project_name}-web-"
  vpc_id      = var.vpc_id
  description = "Security group για τα web instances"

  ingress {
    description     = "HTTP από το ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-web-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_template" "web" {
  name_prefix   = "${var.project_name}-web-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    project_name = var.project_name
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.project_name}-web"
    })
  }
}

resource "aws_autoscaling_group" "web" {
  name                = "${var.project_name}-asg"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [var.target_group_arn]

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 60

  dynamic "tag" {
    for_each = merge(var.tags, { Name = "${var.project_name}-web" })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
