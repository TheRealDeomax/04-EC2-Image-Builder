# Resolving SSM InventoryCollection Failures in EC2 Image Builder

This guide provides solutions for the common "InventoryCollection workflow step failed" error that occurs during the EC2 Image Builder build process.

## The Problem

The error message `InventoryCollection workflow step failed` typically occurs because the AWS Systems Manager (SSM) Agent on the build instance is not properly configured or running when EC2 Image Builder attempts to collect inventory information.

## Solution

We've already implemented the solution in this project:

1. **SSM Agent Component**: A dedicated component (`ssm-agent-setup`) that properly initializes and configures the SSM Agent before any other components run.
2. **Component Order**: The SSM Agent component is placed as the first component in the image recipe to ensure it runs before inventory collection.

## How to Verify

1. Check that the SSM agent component is included in your image recipe as the **first** component:

   ```terraform
   resource "aws_imagebuilder_image_recipe" "web_server_recipe" {
     # ...
     
     # First run the SSM agent setup component
     component {
       component_arn = aws_imagebuilder_component.ssm_agent_setup.arn
     }
     
     # Other components follow
     # ...
   }
   ```

2. Ensure your Image Builder instance profile has the necessary SSM permissions:

   ```terraform
   resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
     role       = aws_iam_role.imagebuilder_role.name
     policy_arn = "arn:aws:iam::aws:policy:AmazonSSMManagedInstanceCore"
   }
   ```

## Troubleshooting Scripts

For troubleshooting SSM issues with EC2 Image Builder, we provide two scripts:

1. **Bash Script**: `scripts/fix-ssm-inventory-error.sh`
   - Creates a new SSM component that configures the agent properly
   - For use on Linux/macOS systems

2. **PowerShell Script**: `scripts/Fix-SSMInventoryError.ps1` 
   - Windows version of the fix script
   - Creates the same component using PowerShell

3. **General Troubleshooting**: `scripts/troubleshoot-imagebuilder.sh`
   - Comprehensive troubleshooting for EC2 Image Builder issues
   - Checks build status, instance details, and SSM connectivity

## Running the Troubleshooting Scripts

### Bash (Linux/macOS)
```bash
# Basic usage
./scripts/troubleshoot-imagebuilder.sh check-image-build <image-arn>

# Check instance details
./scripts/troubleshoot-imagebuilder.sh check-instance <instance-id>
```

### PowerShell (Windows)
```powershell
# Fix SSM InventoryCollection issues
.\scripts\Fix-SSMInventoryError.ps1 -Region us-east-1
```

## Advanced Debugging

If the error persists:

1. Set `terminate_instance_on_failure = false` in your infrastructure configuration to keep the failing instance alive.
2. Connect to the instance using SSM Session Manager (if available) or SSH.
3. Check the following logs:
   - SSM Agent logs: `/var/log/amazon/ssm/amazon-ssm-agent.log`
   - Cloud-init logs: `/var/log/cloud-init-output.log`
   - Image Builder logs: `/var/log/imagebuilder/*`

4. Verify network connectivity to SSM endpoints:
   ```bash
   curl -v https://ssm.us-east-1.amazonaws.com
   curl -v https://ec2messages.us-east-1.amazonaws.com
   curl -v https://ssmmessages.us-east-1.amazonaws.com
   ```

## Prevention

To prevent SSM InventoryCollection failures in future builds:

1. Always include the SSM agent setup component as the first component in any image recipe
2. Ensure proper networking configuration for SSM connectivity
3. Configure appropriate IAM permissions
4. Allow sufficient time (10-15 seconds) after SSM agent installation before proceeding to inventory collection
