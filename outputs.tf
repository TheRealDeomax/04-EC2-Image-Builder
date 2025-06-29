output "image_pipeline_arn" {
  description = "ARN of the Image Builder pipeline"
  value       = aws_imagebuilder_image_pipeline.web_server_pipeline.arn
}

output "image_recipe_arn" {
  description = "ARN of the Image Builder recipe"
  value       = aws_imagebuilder_image_recipe.web_server_recipe.arn
}

output "component_arn" {
  description = "ARN of the custom web server component"
  value       = aws_imagebuilder_component.web_server_component.arn
}

output "infrastructure_configuration_arn" {
  description = "ARN of the infrastructure configuration"
  value       = aws_imagebuilder_infrastructure_configuration.web_server_infra.arn
}

output "distribution_configuration_arn" {
  description = "ARN of the distribution configuration"
  value       = aws_imagebuilder_distribution_configuration.web_server_distribution.arn
}

output "s3_logs_bucket" {
  description = "S3 bucket for Image Builder logs"
  value       = aws_s3_bucket.imagebuilder_logs.bucket
}

output "image_build_arn" {
  description = "ARN of the initial image build"
  value       = aws_imagebuilder_image.web_server_image.arn
}

output "security_group_id" {
  description = "ID of the security group used by Image Builder"
  value       = aws_security_group.image_builder.id
}

output "iam_instance_profile_name" {
  description = "Name of the IAM instance profile for Image Builder"
  value       = aws_iam_instance_profile.imagebuilder_instance_profile.name
}
