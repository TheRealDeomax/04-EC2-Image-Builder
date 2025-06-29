terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}

# Data sources
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# VPC and networking (using default VPC for simplicity)
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security group for Image Builder instances
resource "aws_security_group" "image_builder" {
  name_prefix = "imagebuilder-"
  description = "Security group for EC2 Image Builder instances"
  vpc_id      = data.aws_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "imagebuilder-sg"
  }
}

# IAM Role for Image Builder Instance
resource "aws_iam_role" "imagebuilder_instance_role" {
  name = "EC2ImageBuilderInstanceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "EC2ImageBuilderInstanceRole"
  }
}

# Attach AWS managed policies to the instance role
resource "aws_iam_role_policy_attachment" "imagebuilder_instance_policy" {
  role       = aws_iam_role.imagebuilder_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilder"
}

resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.imagebuilder_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile for the Image Builder instance
resource "aws_iam_instance_profile" "imagebuilder_instance_profile" {
  name = "EC2ImageBuilderInstanceProfile"
  role = aws_iam_role.imagebuilder_instance_role.name
}

# IAM Role for Image Builder Service
resource "aws_iam_role" "imagebuilder_service_role" {
  name = "EC2ImageBuilderServiceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "imagebuilder.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "EC2ImageBuilderServiceRole"
  }
}

# Attach AWS managed policy to the service role
resource "aws_iam_role_policy_attachment" "imagebuilder_service_policy" {
  role       = aws_iam_role.imagebuilder_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/EC2ImageBuilderServiceRolePolicy"
}

# Custom component for installing and configuring HTTP web service
resource "aws_imagebuilder_component" "web_server_component" {
  name     = "install-web-server"
  platform = "Linux"
  version  = "1.0.0"

  data = yamlencode({
    name        = "install-web-server"
    description = "Install and configure a basic HTTP web service"
    schemaVersion = "1.0"

    phases = [
      {
        name = "build"
        steps = [
          {
            name   = "UpdateSystem"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "sudo yum update -y"
              ]
            }
          },
          {
            name   = "InstallHttpd"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "sudo yum install -y httpd"
              ]
            }
          },
          {
            name   = "CreateWebContent"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "sudo mkdir -p /var/www/html",
                "sudo tee /var/www/html/index.html > /dev/null <<EOF",
                "<!DOCTYPE html>",
                "<html>",
                "<head>",
                "    <title>Welcome to My Custom AMI</title>",
                "    <style>",
                "        body { font-family: Arial, sans-serif; margin: 50px; background-color: #f0f0f0; }",
                "        .container { background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }",
                "        h1 { color: #333; text-align: center; }",
                "        .info { background-color: #e8f4fd; padding: 15px; border-radius: 5px; margin: 20px 0; }",
                "        .status { color: #28a745; font-weight: bold; }",
                "    </style>",
                "</head>",
                "<body>",
                "    <div class=\"container\">",
                "        <h1>🚀 Welcome to Your Custom Amazon Linux AMI</h1>",
                "        <div class=\"info\">",
                "            <p><strong>Server Status:</strong> <span class=\"status\">✅ Running</span></p>",
                "            <p><strong>Web Server:</strong> Apache HTTP Server</p>",
                "            <p><strong>Operating System:</strong> Amazon Linux 2023</p>",
                "            <p><strong>Built with:</strong> EC2 Image Builder</p>",
                "            <p><strong>Instance ID:</strong> <span id=\"instance-id\">Loading...</span></p>",
                "            <p><strong>Current Time:</strong> <span id=\"current-time\"></span></p>",
                "        </div>",
                "        <p>This AMI was created using EC2 Image Builder with a custom component that:</p>",
                "        <ul>",
                "            <li>Updates the system packages</li>",
                "            <li>Installs Apache HTTP Server</li>",
                "            <li>Configures the web service to start automatically</li>",
                "            <li>Creates this custom welcome page</li>",
                "        </ul>",
                "    </div>",
                "    <script>",
                "        // Update current time",
                "        function updateTime() {",
                "            document.getElementById('current-time').textContent = new Date().toLocaleString();",
                "        }",
                "        updateTime();",
                "        setInterval(updateTime, 1000);",
                "        ",
                "        // Fetch instance metadata",
                "        fetch('/latest/meta-data/instance-id')",
                "            .then(response => response.text())",
                "            .then(data => {",
                "                document.getElementById('instance-id').textContent = data;",
                "            })",
                "            .catch(error => {",
                "                document.getElementById('instance-id').textContent = 'Unable to fetch';",
                "            });",
                "    </script>",
                "</body>",
                "</html>",
                "EOF"
              ]
            }
          },
          {
            name   = "ConfigureHttpd"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "sudo systemctl enable httpd",
                "sudo systemctl start httpd",
                "sudo chown -R apache:apache /var/www/html",
                "sudo chmod -R 755 /var/www/html"
              ]
            }
          },
          {
            name   = "ConfigureFirewall"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "# Configure iptables to allow HTTP traffic",
                "sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT",
                "sudo service iptables save || echo 'iptables-services not installed, skipping save'"
              ]
            }
          },
          {
            name   = "CreateHealthCheck"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "sudo tee /var/www/html/health > /dev/null <<EOF",
                "OK",
                "EOF",
                "sudo tee /etc/systemd/system/web-health-check.service > /dev/null <<EOF",
                "[Unit]",
                "Description=Web Health Check Service",
                "After=httpd.service",
                "",
                "[Service]",
                "Type=oneshot",
                "ExecStart=/bin/bash -c 'curl -f http://localhost/health || exit 1'",
                "",
                "[Install]",
                "WantedBy=multi-user.target",
                "EOF",
                "sudo systemctl enable web-health-check.service"
              ]
            }
          }
        ]
      },
      {
        name = "validate"
        steps = [
          {
            name   = "ValidateHttpdInstallation"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "sudo systemctl is-active httpd",
                "sudo systemctl is-enabled httpd",
                "curl -f http://localhost/ || exit 1",
                "curl -f http://localhost/health || exit 1"
              ]
            }
          }
        ]
      }
    ]
  })

  tags = {
    Name = "web-server-component"
  }
}

# Image recipe
resource "aws_imagebuilder_image_recipe" "web_server_recipe" {
  name         = "amazon-linux-web-server-recipe"
  parent_image = var.parent_image
  version      = "1.0.0"

  component {
    component_arn = aws_imagebuilder_component.web_server_component.arn
  }

  # Add AWS managed components for security updates
  component {
    component_arn = "arn:aws:imagebuilder:${data.aws_region.current.name}:aws:component/update-linux/x.x.x"
  }

  tags = {
    Name = "amazon-linux-web-server-recipe"
  }
}

# Infrastructure configuration
resource "aws_imagebuilder_infrastructure_configuration" "web_server_infra" {
  name                          = "web-server-infrastructure"
  instance_profile_name         = aws_iam_instance_profile.imagebuilder_instance_profile.name
  instance_types                = var.instance_types
  security_group_ids           = [aws_security_group.image_builder.id]
  subnet_id                    = data.aws_subnets.default.ids[0]
  terminate_instance_on_failure = true

  logging {
    s3_logs {
      s3_bucket_name = aws_s3_bucket.imagebuilder_logs.bucket
      s3_key_prefix  = "image-builder-logs"
    }
  }

  tags = {
    Name = "web-server-infrastructure"
  }
}

# S3 bucket for Image Builder logs
resource "aws_s3_bucket" "imagebuilder_logs" {
  bucket        = "imagebuilder-logs-${random_string.bucket_suffix.result}"
  force_destroy = true

  tags = {
    Name = "imagebuilder-logs"
  }
}

resource "aws_s3_bucket_versioning" "imagebuilder_logs_versioning" {
  bucket = aws_s3_bucket.imagebuilder_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "imagebuilder_logs_encryption" {
  bucket = aws_s3_bucket.imagebuilder_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Distribution configuration
resource "aws_imagebuilder_distribution_configuration" "web_server_distribution" {
  name = "web-server-distribution"

  distribution {
    ami_distribution_configuration {
      name               = "amazon-linux-web-server-{{ imagebuilder:buildDate }}"
      description        = "Amazon Linux AMI with pre-configured web server"
      ami_tags = {
        Name        = "amazon-linux-web-server"
        Environment = var.environment
        BuildDate   = "{{ imagebuilder:buildDate }}"
        CreatedBy   = "EC2ImageBuilder"
      }
    }
    region = data.aws_region.current.name
  }

  tags = {
    Name = "web-server-distribution"
  }
}

# Image pipeline
resource "aws_imagebuilder_image_pipeline" "web_server_pipeline" {
  name                             = "amazon-linux-web-server-pipeline"
  description                      = "Pipeline to build Amazon Linux AMI with web server"
  image_recipe_arn                = aws_imagebuilder_image_recipe.web_server_recipe.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.web_server_infra.arn
  distribution_configuration_arn   = aws_imagebuilder_distribution_configuration.web_server_distribution.arn

  schedule {
    schedule_expression                = "cron(0 2 * * ? *)"  # Daily at 2 AM
    pipeline_execution_start_condition = "EXPRESSION_MATCH_AND_DEPENDENCY_UPDATES_AVAILABLE"
  }

  image_tests_configuration {
    image_tests_enabled                = true
    timeout_minutes                    = 720
  }

  tags = {
    Name = "amazon-linux-web-server-pipeline"
  }
}

# Trigger initial image build
resource "aws_imagebuilder_image" "web_server_image" {
  distribution_configuration_arn   = aws_imagebuilder_distribution_configuration.web_server_distribution.arn
  image_recipe_arn                = aws_imagebuilder_image_recipe.web_server_recipe.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.web_server_infra.arn

  image_tests_configuration {
    image_tests_enabled = true
    timeout_minutes     = 720
  }

  tags = {
    Name = "amazon-linux-web-server-image"
  }
}
