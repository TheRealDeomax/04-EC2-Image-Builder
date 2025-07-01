# ============================================================================
# EC2 Image Builder Pipeline - Complete Implementation
# Following AWS Documentation Best Practices
# ============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ============================================================================
# DATA SOURCES
# ============================================================================

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ============================================================================
# IAM ROLES AND POLICIES
# ============================================================================

# IAM Role for EC2 Image Builder Instance
# This role is assumed by EC2 instances during the image building process
resource "aws_iam_role" "imagebuilder_instance_role" {
  name = "${var.project_name}-imagebuilder-instance-role"
  
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
    Name        = "${var.project_name}-imagebuilder-instance-role"
    Environment = var.environment
    Purpose     = "EC2 Image Builder Instance Role"
  }
}

# Attach AWS managed policy for Image Builder instance
resource "aws_iam_role_policy_attachment" "instance_profile_policy" {
  role       = aws_iam_role.imagebuilder_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilder"
}

# Attach AWS managed policy for SSM
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.imagebuilder_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create instance profile for the role
resource "aws_iam_instance_profile" "imagebuilder_instance_profile" {
  name = "${var.project_name}-imagebuilder-instance-profile"
  role = aws_iam_role.imagebuilder_instance_role.name

  tags = {
    Name        = "${var.project_name}-imagebuilder-instance-profile"
    Environment = var.environment
  }
}

# ============================================================================
# SECURITY GROUPS
# ============================================================================

# Security group for Image Builder instances
resource "aws_security_group" "imagebuilder_sg" {
  name_prefix = "${var.project_name}-imagebuilder-"
  description = "Security group for EC2 Image Builder instances"
  vpc_id      = data.aws_vpc.default.id

  # Outbound rules for downloading packages and accessing AWS services
  egress {
    description = "HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTP outbound"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "DNS outbound"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-imagebuilder-sg"
    Environment = var.environment
    Purpose     = "Image Builder Security Group"
  }
}

# ============================================================================
# IMAGE BUILDER COMPONENTS
# ============================================================================

# Component 1: System Updates
resource "aws_imagebuilder_component" "update_linux" {
  name        = "${var.project_name}-update-linux"
  description = "Update Linux packages to latest versions"
  platform    = "Linux"
  version     = "1.0.0"

  data = yamlencode({
    name          = "${var.project_name}-update-linux"
    description   = "Update all system packages"
    schemaVersion = "1.0"
    
    phases = [
      {
        name = "build"
        steps = [
          {
            name   = "UpdateLinuxPackages"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "#!/bin/bash",
                "set -e",
                "echo '=== Starting System Update ==='",
                "echo 'Current date: $(date)'",
                "echo 'System info: $(uname -a)'",
                "",
                "# Update package lists and upgrade system",
                "if command -v dnf &> /dev/null; then",
                "    echo 'Using DNF package manager'",
                "    dnf clean all",
                "    dnf makecache",
                "    dnf update -y",
                "elif command -v yum &> /dev/null; then",
                "    echo 'Using YUM package manager'",
                "    yum clean all",
                "    yum makecache",
                "    yum update -y",
                "else",
                "    echo 'No supported package manager found'",
                "    exit 1",
                "fi",
                "",
                "echo '=== System Update Complete ==='",
                "echo 'Updated on: $(date)'"
              ]
            }
          }
        ]
      },
      {
        name = "validate"
        steps = [
          {
            name   = "ValidateUpdate"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "echo 'Validating system update...'",
                "echo 'System uptime: $(uptime)'",
                "echo 'Available disk space:'",
                "df -h",
                "echo 'Memory usage:'",
                "free -h"
              ]
            }
          }
        ]
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-update-linux"
    Environment = var.environment
    Component   = "SystemUpdate"
  }
}

# Component 2: Install and Configure SSM Agent
resource "aws_imagebuilder_component" "install_ssm_agent" {
  name        = "${var.project_name}-install-ssm-agent"
  description = "Install and configure Amazon SSM Agent"
  platform    = "Linux"
  version     = "1.0.0"

  data = yamlencode({
    name          = "${var.project_name}-install-ssm-agent"
    description   = "Install and configure Amazon SSM Agent for remote management"
    schemaVersion = "1.0"
    
    phases = [
      {
        name = "build"
        steps = [
          {
            name   = "InstallSSMAgent"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "#!/bin/bash",
                "set -e",
                "echo '=== Installing Amazon SSM Agent ==='",
                "",
                "# Install SSM Agent based on the package manager",
                "if command -v dnf &> /dev/null; then",
                "    echo 'Installing SSM Agent using DNF'",
                "    dnf install -y amazon-ssm-agent",
                "elif command -v yum &> /dev/null; then",
                "    echo 'Installing SSM Agent using YUM'",
                "    yum install -y amazon-ssm-agent",
                "else",
                "    echo 'No supported package manager found'",
                "    exit 1",
                "fi",
                "",
                "# Enable and start SSM Agent",
                "echo 'Enabling SSM Agent service'",
                "systemctl enable amazon-ssm-agent",
                "systemctl start amazon-ssm-agent",
                "",
                "# Wait a moment for service to start",
                "sleep 5",
                "",
                "# Verify SSM Agent is running",
                "if systemctl is-active amazon-ssm-agent; then",
                "    echo 'SSM Agent is running successfully'",
                "else",
                "    echo 'Failed to start SSM Agent'",
                "    systemctl status amazon-ssm-agent",
                "    exit 1",
                "fi",
                "",
                "echo '=== SSM Agent Installation Complete ==='",
                "echo 'SSM Agent version: $(amazon-ssm-agent -version | head -1)'"
              ]
            }
          }
        ]
      },
      {
        name = "validate"
        steps = [
          {
            name   = "ValidateSSMAgent"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "echo 'Validating SSM Agent installation...'",
                "systemctl status amazon-ssm-agent",
                "amazon-ssm-agent -version"
              ]
            }
          }
        ]
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-install-ssm-agent"
    Environment = var.environment
    Component   = "SSMAgent"
  }
}

# Component 3: Install Web Server and Create Web Application
resource "aws_imagebuilder_component" "install_web_server" {
  name        = "${var.project_name}-install-web-server"
  description = "Install Apache web server and create a simple web application"
  platform    = "Linux"
  version     = "1.0.0"

  data = yamlencode({
    name          = "${var.project_name}-install-web-server"
    description   = "Install Apache HTTP server and create a basic web application"
    schemaVersion = "1.0"
    
    phases = [
      {
        name = "build"
        steps = [
          {
            name   = "InstallApache"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "#!/bin/bash",
                "set -e",
                "echo '=== Installing Apache Web Server ==='",
                "",
                "# Install Apache based on the package manager",
                "if command -v dnf &> /dev/null; then",
                "    echo 'Installing Apache using DNF'",
                "    dnf install -y httpd",
                "elif command -v yum &> /dev/null; then",
                "    echo 'Installing Apache using YUM'",
                "    yum install -y httpd",
                "else",
                "    echo 'No supported package manager found'",
                "    exit 1",
                "fi",
                "",
                "# Enable and start Apache",
                "echo 'Enabling Apache service'",
                "systemctl enable httpd",
                "systemctl start httpd",
                "",
                "# Wait a moment for service to start",
                "sleep 5",
                "",
                "# Verify Apache is running",
                "if systemctl is-active httpd; then",
                "    echo 'Apache is running successfully'",
                "else",
                "    echo 'Failed to start Apache'",
                "    systemctl status httpd",
                "    exit 1",
                "fi",
                "",
                "echo '=== Apache Installation Complete ==='",
                "httpd -v"
              ]
            }
          },
          {
            name   = "CreateWebApplication"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "#!/bin/bash",
                "set -e",
                "echo '=== Creating Web Application ==='",
                "",
                "# Create main index.html",
                "cat > /var/www/html/index.html << 'EOF'",
                "<!DOCTYPE html>",
                "<html lang=\"en\">",
                "<head>",
                "    <meta charset=\"UTF-8\">",
                "    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">",
                "    <title>EC2 Image Builder - Web Server</title>",
                "    <style>",
                "        * {",
                "            margin: 0;",
                "            padding: 0;",
                "            box-sizing: border-box;",
                "        }",
                "        body {",
                "            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;",
                "            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);",
                "            min-height: 100vh;",
                "            display: flex;",
                "            align-items: center;",
                "            justify-content: center;",
                "            padding: 20px;",
                "        }",
                "        .container {",
                "            background: white;",
                "            border-radius: 15px;",
                "            box-shadow: 0 20px 40px rgba(0,0,0,0.1);",
                "            padding: 40px;",
                "            max-width: 800px;",
                "            width: 100%;",
                "            text-align: center;",
                "        }",
                "        .header {",
                "            color: #333;",
                "            margin-bottom: 30px;",
                "        }",
                "        .header h1 {",
                "            font-size: 2.5em;",
                "            margin-bottom: 10px;",
                "            color: #667eea;",
                "        }",
                "        .status {",
                "            background: #d4edda;",
                "            color: #155724;",
                "            padding: 15px;",
                "            border-radius: 8px;",
                "            margin: 20px 0;",
                "            border: 1px solid #c3e6cb;",
                "        }",
                "        .info-grid {",
                "            display: grid;",
                "            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));",
                "            gap: 20px;",
                "            margin: 30px 0;",
                "        }",
                "        .info-card {",
                "            background: #f8f9fa;",
                "            padding: 20px;",
                "            border-radius: 10px;",
                "            border-left: 4px solid #667eea;",
                "        }",
                "        .info-card h3 {",
                "            color: #333;",
                "            margin-bottom: 10px;",
                "        }",
                "        .feature-list {",
                "            text-align: left;",
                "            margin: 20px 0;",
                "        }",
                "        .feature-list li {",
                "            padding: 8px 0;",
                "            list-style: none;",
                "            position: relative;",
                "            padding-left: 25px;",
                "        }",
                "        .feature-list li:before {",
                "            content: '✅';",
                "            position: absolute;",
                "            left: 0;",
                "        }",
                "        .footer {",
                "            margin-top: 30px;",
                "            padding-top: 20px;",
                "            border-top: 1px solid #dee2e6;",
                "            color: #6c757d;",
                "        }",
                "        @media (max-width: 600px) {",
                "            .container {",
                "                padding: 20px;",
                "            }",
                "            .header h1 {",
                "                font-size: 2em;",
                "            }",
                "        }",
                "    </style>",
                "</head>",
                "<body>",
                "    <div class=\"container\">",
                "        <div class=\"header\">",
                "            <h1>🚀 EC2 Image Builder</h1>",
                "            <p>Amazon Linux Web Server</p>",
                "        </div>",
                "        ",
                "        <div class=\"status\">",
                "            <strong>✅ Server Successfully Deployed!</strong><br>",
                "            Built with EC2 Image Builder on $(date)",
                "        </div>",
                "",
                "        <div class=\"info-grid\">",
                "            <div class=\"info-card\">",
                "                <h3>🖥️ System Information</h3>",
                "                <p><strong>OS:</strong> Amazon Linux 2023</p>",
                "                <p><strong>Web Server:</strong> Apache HTTP</p>",
                "                <p><strong>Management:</strong> SSM Agent</p>",
                "            </div>",
                "            <div class=\"info-card\">",
                "                <h3>🔧 Build Information</h3>",
                "                <p><strong>Build Date:</strong> $(date +'%Y-%m-%d')</p>",
                "                <p><strong>Build Time:</strong> $(date +'%H:%M:%S UTC')</p>",
                "                <p><strong>Builder:</strong> EC2 Image Builder</p>",
                "            </div>",
                "        </div>",
                "",
                "        <div class=\"feature-list\">",
                "            <h3>📦 Installed Features:</h3>",
                "            <ul>",
                "                <li>Latest system security updates</li>",
                "                <li>Apache HTTP Server (auto-start enabled)</li>",
                "                <li>Amazon SSM Agent for remote management</li>",
                "                <li>Custom web application with responsive design</li>",
                "                <li>Automated service configuration</li>",
                "                <li>Health monitoring endpoints</li>",
                "            </ul>",
                "        </div>",
                "",
                "        <div class=\"footer\">",
                "            <p>This AMI was built using AWS EC2 Image Builder following best practices.</p>",
                "            <p>Server is ready for production workloads.</p>",
                "        </div>",
                "    </div>",
                "</body>",
                "</html>",
                "EOF",
                "",
                "# Create a health check endpoint",
                "cat > /var/www/html/health.html << 'EOF'",
                "{",
                "  \"status\": \"healthy\",",
                "  \"timestamp\": \"$(date -Iseconds)\",",
                "  \"services\": {",
                "    \"httpd\": \"running\",",
                "    \"ssm-agent\": \"running\"",
                "  },",
                "  \"uptime\": \"$(uptime)\"",
                "}",
                "EOF",
                "",
                "# Set proper permissions",
                "chown -R apache:apache /var/www/html/",
                "chmod -R 644 /var/www/html/*",
                "",
                "echo '=== Web Application Created Successfully ==='",
                "ls -la /var/www/html/"
              ]
            }
          }
        ]
      },
      {
        name = "validate"
        steps = [
          {
            name   = "ValidateWebServer"
            action = "ExecuteBash"
            inputs = {
              commands = [
                "echo 'Validating web server installation...'",
                "systemctl status httpd",
                "curl -s http://localhost/ | grep -q 'EC2 Image Builder'",
                "curl -s http://localhost/health.html | grep -q 'healthy'",
                "echo 'Web server validation complete!'"
              ]
            }
          }
        ]
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-install-web-server"
    Environment = var.environment
    Component   = "WebServer"
  }
}

# ============================================================================
# IMAGE RECIPE
# ============================================================================

resource "aws_imagebuilder_image_recipe" "web_server_recipe" {
  name         = "${var.project_name}-web-server-recipe"
  description  = "Recipe for building Amazon Linux web server with Apache and SSM"
  parent_image = var.parent_image_arn
  version      = "1.0.0"

  # Add components in order
  component {
    component_arn = aws_imagebuilder_component.update_linux.arn
  }

  component {
    component_arn = aws_imagebuilder_component.install_ssm_agent.arn
  }

  component {
    component_arn = aws_imagebuilder_component.install_web_server.arn
  }

  tags = {
    Name        = "${var.project_name}-web-server-recipe"
    Environment = var.environment
    Purpose     = "Web Server Image Recipe"
  }
}

# ============================================================================
# INFRASTRUCTURE CONFIGURATION
# ============================================================================

resource "aws_imagebuilder_infrastructure_configuration" "web_server_infra" {
  name                          = "${var.project_name}-web-server-infra"
  description                   = "Infrastructure configuration for web server image building"
  instance_profile_name         = aws_iam_instance_profile.imagebuilder_instance_profile.name
  instance_types                = var.instance_types
  subnet_id                     = data.aws_subnets.default.ids[0]
  security_group_ids            = [aws_security_group.imagebuilder_sg.id]
  terminate_instance_on_failure = true

  dynamic "logging" {
    for_each = var.enable_logging ? [1] : []
    content {
      s3_logs {
        s3_bucket_name = aws_s3_bucket.imagebuilder_logs[0].bucket
        s3_key_prefix  = "image-builder-logs"
      }
    }
  }

  tags = {
    Name        = "${var.project_name}-web-server-infra"
    Environment = var.environment
    Purpose     = "Image Builder Infrastructure"
  }
}

# ============================================================================
# S3 BUCKET FOR LOGS (CONDITIONAL)
# ============================================================================

resource "aws_s3_bucket" "imagebuilder_logs" {
  count  = var.enable_logging ? 1 : 0
  bucket = "${var.project_name}-imagebuilder-logs-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "${var.project_name}-imagebuilder-logs"
    Environment = var.environment
    Purpose     = "Image Builder Logs"
  }
}

resource "aws_s3_bucket_versioning" "imagebuilder_logs_versioning" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.imagebuilder_logs[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "imagebuilder_logs_encryption" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.imagebuilder_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "imagebuilder_logs_pab" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.imagebuilder_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# ============================================================================
# DISTRIBUTION CONFIGURATION
# ============================================================================

resource "aws_imagebuilder_distribution_configuration" "web_server_distribution" {
  name        = "${var.project_name}-web-server-distribution"
  description = "Distribution configuration for web server AMI"

  distribution {
    region = var.aws_region

    ami_distribution_configuration {
      name               = "${var.project_name}-web-server-{{ imagebuilder:buildDate }}"
      description        = "Amazon Linux web server with Apache and SSM Agent"
      target_account_ids = [data.aws_caller_identity.current.account_id]
      
      # Explicitly configure AMI permissions to prevent public sharing
      ami_tags = {
        Name         = "${var.project_name}-web-server"
        Environment  = var.environment
        BuildDate    = "{{ imagebuilder:buildDate }}"
        BaseImage    = "Amazon Linux 2023"
        WebServer    = "Apache"
        SSMAgent     = "Installed"
        CreatedBy    = "EC2-Image-Builder"
        Project      = var.project_name
      }
      
      # Ensure AMI is private - only accessible within the account
      ami_permissions {
        user_ids = []  # Empty list means no additional users
        user_groups = []  # Empty list means no public access
      }
    }
  }

  tags = {
    Name        = "${var.project_name}-web-server-distribution"
    Environment = var.environment
    Purpose     = "AMI Distribution Configuration"
  }
}

data "aws_caller_identity" "current" {}

# ============================================================================
# IMAGE PIPELINE
# ============================================================================

resource "aws_imagebuilder_image_pipeline" "web_server_pipeline" {
  name                             = "${var.project_name}-web-server-pipeline"
  description                      = "Pipeline for building web server AMIs"
  image_recipe_arn                 = aws_imagebuilder_image_recipe.web_server_recipe.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.web_server_infra.arn
  distribution_configuration_arn   = aws_imagebuilder_distribution_configuration.web_server_distribution.arn
  status                           = "ENABLED"

  image_tests_configuration {
    image_tests_enabled = true
    timeout_minutes     = 720
  }

  dynamic "schedule" {
    for_each = var.enable_schedule ? [1] : []
    content {
      schedule_expression = var.schedule_expression
      pipeline_execution_start_condition = "EXPRESSION_MATCH_AND_DEPENDENCY_UPDATES_AVAILABLE"
    }
  }

  tags = {
    Name        = "${var.project_name}-web-server-pipeline"
    Environment = var.environment
    Purpose     = "Web Server Image Pipeline"
  }
}
