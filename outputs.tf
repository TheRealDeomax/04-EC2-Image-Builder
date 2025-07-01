# ============================================================================
# OUTPUTS - EC2 Image Builder Resources
# ============================================================================

# Pipeline Information
output "image_pipeline_arn" {
  description = "ARN of the EC2 Image Builder pipeline"
  value       = aws_imagebuilder_image_pipeline.web_server_pipeline.arn
}

output "image_pipeline_name" {
  description = "Name of the EC2 Image Builder pipeline"
  value       = aws_imagebuilder_image_pipeline.web_server_pipeline.name
}

# Recipe Information  
output "image_recipe_arn" {
  description = "ARN of the Image Builder recipe"
  value       = aws_imagebuilder_image_recipe.web_server_recipe.arn
}

output "image_recipe_name" {
  description = "Name of the Image Builder recipe"
  value       = aws_imagebuilder_image_recipe.web_server_recipe.name
}

# Component Information
output "update_component_arn" {
  description = "ARN of the Linux update component"
  value       = aws_imagebuilder_component.update_linux.arn
}

output "ssm_component_arn" {
  description = "ARN of the SSM Agent component"
  value       = aws_imagebuilder_component.install_ssm_agent.arn
}

output "web_server_component_arn" {
  description = "ARN of the web server component"
  value       = aws_imagebuilder_component.install_web_server.arn
}

# Infrastructure Information
output "infrastructure_configuration_arn" {
  description = "ARN of the infrastructure configuration"
  value       = aws_imagebuilder_infrastructure_configuration.web_server_infra.arn
}

output "distribution_configuration_arn" {
  description = "ARN of the distribution configuration"
  value       = aws_imagebuilder_distribution_configuration.web_server_distribution.arn
}

# IAM Information
output "instance_profile_name" {
  description = "Name of the IAM instance profile for Image Builder"
  value       = aws_iam_instance_profile.imagebuilder_instance_profile.name
}

output "instance_role_arn" {
  description = "ARN of the IAM role for Image Builder instances"
  value       = aws_iam_role.imagebuilder_instance_role.arn
}

# Security Group Information
output "security_group_id" {
  description = "ID of the security group for Image Builder instances"
  value       = aws_security_group.imagebuilder_sg.id
}

# S3 Bucket Information
output "logs_bucket_name" {
  description = "Name of the S3 bucket for Image Builder logs (if logging enabled)"
  value       = var.enable_logging ? aws_s3_bucket.imagebuilder_logs[0].bucket : "Logging disabled"
}

# Configuration Values
output "project_configuration" {
  description = "Project configuration summary"
  value = {
    project_name   = var.project_name
    environment    = var.environment
    aws_region     = var.aws_region
    instance_types = var.instance_types
    parent_image   = var.parent_image_arn
  }
}

# Instructions
output "next_steps" {
  description = "Instructions for next steps after deployment"
  value       = <<-EOT
    
    ========================================
    EC2 Image Builder Pipeline Deployed!
    ========================================
    
    Next Steps:
    1. Go to AWS Console → EC2 Image Builder
    2. Navigate to "Image pipelines"
    3. Find pipeline: ${aws_imagebuilder_image_pipeline.web_server_pipeline.name}
    4. Click "Actions" → "Run pipeline"
    5. Monitor build progress (typically 15-30 minutes)
    6. Once complete, launch EC2 instance using the new AMI
    7. Access your web application at http://[instance-public-ip]
    
    Pipeline ARN: ${aws_imagebuilder_image_pipeline.web_server_pipeline.arn}
    Region: ${var.aws_region}
    
    ========================================
    
  EOT
}
