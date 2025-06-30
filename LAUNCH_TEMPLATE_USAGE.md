# Launch Template Usage

The `launch-template.tf` file contains a launch template configuration that can be used to easily launch EC2 instances using your custom-built AMI.

## Current Status

The launch template is included in the configuration and will initially use the base Amazon Linux 2023 AMI as a fallback. Once your custom Image Builder pipeline creates an AMI, the data source will automatically find and use your custom AMI instead.

## AMI Selection Logic

The launch template data source looks for AMIs in this order:
1. **Custom AMIs** with name pattern "amazon-linux-web-*" (built by your pipeline)
2. **Fallback** to Amazon Linux 2023 AMIs with pattern "al2023-ami-*"

## After Your First Image Build

1. **Wait for the Image Builder pipeline to complete** (15-30 minutes)
2. **Run terraform refresh** to update the data source:
   ```powershell
   terraform refresh
   ```
3. **Check the updated AMI**:
   ```powershell
   terraform output latest_ami_id
   ```
4. **Apply if needed** to update the launch template:
   ```powershell
   terraform apply
   ```

## Manual Instance Launch (Alternative)

Instead of using the launch template, you can manually launch an EC2 instance:

1. Go to the EC2 console
2. Click "Launch Instance"
3. In "Application and OS Images", click "My AMIs"
4. Select your custom AMI (will be named like "amazon-linux-web-YYYY-MM-DD...")
5. Choose instance type: `t3.micro` or `t2.micro` (free tier eligible)
6. Configure security group to allow HTTP (port 80) traffic
7. Launch the instance

## Testing Your Web Server

Once your instance is running:
1. Get the public IP address from the EC2 console
2. Open a web browser and navigate to: `http://[your-instance-public-ip]`
3. You should see your custom web application with server information

## Security Group Requirements

Make sure your instance's security group allows:
- **Inbound**: HTTP (port 80) from 0.0.0.0/0
- **Outbound**: All traffic (for updates and package installation)

The launch template includes a pre-configured security group that allows this traffic.
