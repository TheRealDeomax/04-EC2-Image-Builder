# Optional: Launch Template for deploying instances from the built AMI
# Uncomment and modify this section if you want to automatically create 
# a launch template for easy instance deployment

# Security group for web server instances (allows HTTP traffic)
resource "aws_security_group" "web_server" {
  name_prefix = "web-server-"
  description = "Security group for web server instances"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Restrict this to your IP for better security
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-server-sg"
  }
}

# Data source to get the latest built AMI
data "aws_ami" "latest_web_server" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["amazon-linux-web-server-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  depends_on = [aws_imagebuilder_image.web_server_image]
}

# Launch template for the web server instances
resource "aws_launch_template" "web_server" {
  name_prefix   = "web-server-"
  description   = "Launch template for web server instances"
  image_id      = data.aws_ami.latest_web_server.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.web_server.id]

  key_name = var.key_pair_name  # Optional: specify your key pair

  user_data = base64encode(<<-EOF
    #!/bin/bash
    # Additional startup commands if needed
    sudo systemctl enable httpd
    sudo systemctl start httpd
    
    # Optional: Add instance-specific customizations
    echo "<p><strong>Instance launched at:</strong> $(date)</p>" | sudo tee -a /var/www/html/index.html
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "web-server-instance"
      Environment = var.environment
      Project     = var.project_name
    }
  }

  tags = {
    Name = "web-server-launch-template"
  }
}

# Optional: Auto Scaling Group for high availability
resource "aws_autoscaling_group" "web_server" {
  count               = var.create_auto_scaling ? 1 : 0
  name                = "web-server-asg"
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns   = var.target_group_arns
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  launch_template {
    id      = aws_launch_template.web_server.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "web-server-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}

# Output the launch template ID and AMI ID
output "launch_template_id" {
  description = "ID of the launch template for web server instances"
  value       = aws_launch_template.web_server.id
}

output "latest_ami_id" {
  description = "ID of the latest built AMI"
  value       = data.aws_ami.latest_web_server.id
}

output "web_server_security_group_id" {
  description = "ID of the security group for web server instances"
  value       = aws_security_group.web_server.id
}
