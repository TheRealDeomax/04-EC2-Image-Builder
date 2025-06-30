# EC2 Image Builder Parent Image Error Fix

This guide provides solutions for the common "ResourceNotFoundException: The following required resource 'Image' cannot be found" error that occurs during the EC2 Image Builder deployment.

## The Problem

When you see an error like this:
```
Error: creating Image Builder Image Recipe: operation error imagebuilder: CreateImageRecipe, https response error StatusCode: 404, RequestID: 4e857f7f-5cfe-498e-b0c4-5a83752e4ecd, api error ResourceNotFoundException: The following required resource 'Image' cannot be found: 'arn:aws:imagebuilder:us-east-1:aws:image/amazon-linux-2023-x86/2023.3.20240624'.
```

This typically means that:
1. The parent image ARN specified in your configuration doesn't exist
2. AWS may have removed or updated the image you're referencing
3. You might be using a newer version that hasn't been released yet

## Quick Fix

1. **Update the parent_image variable** in your `variables.tf` file to use one of these known working Amazon Linux 2023 image ARNs:

   ```terraform
   variable "parent_image" {
     description = "Parent AMI for the image recipe"
     type        = string
     default     = "arn:aws:imagebuilder:us-east-1:aws:image/amazon-linux-2023-x86/2023.3.20240306"
   }
   ```

   Alternative working ARNs:
   - `arn:aws:imagebuilder:us-east-1:aws:image/amazon-linux-2023-x86/2023.2.20231218`
   - `arn:aws:imagebuilder:us-east-1:aws:image/amazon-linux-2023-x86/2023.1.20230906`
   - `arn:aws:imagebuilder:us-east-1:aws:image/amazon-linux-2-x86/2023.3.20240611`

2. **Run terraform plan** to verify the changes
   ```
   terraform plan
   ```

3. **Apply the changes** if the plan looks good
   ```
   terraform apply
   ```

## Using the Fix-ParentImageARN.ps1 Script

We've included a PowerShell script to help you find and update parent image ARNs:

```powershell
# Run the script to see available parent images
.\scripts\Fix-ParentImageARN.ps1

# Specify a different filter (e.g., for Amazon Linux 2)
.\scripts\Fix-ParentImageARN.ps1 -Filter "amazon-linux-2"

# Specify a different region
.\scripts\Fix-ParentImageARN.ps1 -Region "us-west-2"
```

This script will:
1. Find valid parent images that match your filter
2. Let you select which one to use
3. Update your Terraform configuration files with the correct ARN

## Finding Available Parent Images

You can also use these scripts to list available parent images:

**PowerShell:**
```powershell
# Run the PowerShell parent image finder
.\list-parent-images.ps1
```

**Bash:**
```bash
# Run the Bash parent image finder
bash list-parent-images.sh images amazon-linux-2023
```

## Recommended Best Practices

1. **Use a terraform.tfvars file** to override the parent_image variable, instead of modifying variables.tf:
   ```
   parent_image = "arn:aws:imagebuilder:us-east-1:aws:image/amazon-linux-2023-x86/2023.3.20240306"
   ```

2. **Check for new parent images periodically** as AWS releases updates

3. **Keep multiple working ARNs as comments** in your configuration for quick fallbacks

## Troubleshooting Further Issues

If you continue having issues with parent images:

1. Check that AWS CLI is properly configured with valid credentials
2. Verify that the region in your parent image ARN matches your deployment region
3. Try using Amazon Linux 2 instead of Amazon Linux 2023 if problems persist
4. Check AWS Service Health Dashboard for any EC2 Image Builder service issues
