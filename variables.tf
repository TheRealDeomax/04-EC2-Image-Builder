variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "parent_image" {
  description = "Parent AMI for the image recipe"
  type        = string
  default     = "arn:aws:imagebuilder:us-east-1:aws:image/amazon-linux-2023-x86/x.x.x"
}

variable "instance_types" {
  description = "List of instance types for Image Builder"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "web-server-imagebuilder"
}

# Optional variables for launch template and auto scaling
variable "key_pair_name" {
  description = "Name of the EC2 key pair for SSH access (optional)"
  type        = string
  default     = null
}

variable "create_auto_scaling" {
  description = "Whether to create an Auto Scaling Group"
  type        = bool
  default     = false
}

variable "target_group_arns" {
  description = "List of target group ARNs for load balancer (optional)"
  type        = list(string)
  default     = []
}

variable "asg_min_size" {
  description = "Minimum size of the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum size of the Auto Scaling Group"
  type        = number
  default     = 3
}

variable "asg_desired_capacity" {
  description = "Desired capacity of the Auto Scaling Group"
  type        = number
  default     = 2
}
