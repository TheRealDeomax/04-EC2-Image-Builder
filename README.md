# EC2 Image Builder for Amazon Linux with Web Server

This Terraform configuration creates an EC2 Image Builder pipeline that builds a custom Amazon Linux AMI with a pre-configured HTTP web service.

## What This Creates

### Infrastructure Components
- **IAM Roles and Policies**: Required roles for EC2 Image Builder service and instances
- **Security Group**: Allows outbound traffic for Image Builder instances
- **S3 Bucket**: Stores Image Builder logs with encryption and versioning
- **VPC Configuration**: Uses the default VPC and subnets

### Image Builder Components
- **Custom Component**: Installs and configures Apache HTTP server
- **Image Recipe**: Combines the base Amazon Linux image with custom components
- **Infrastructure Configuration**: Defines the build environment
- **Distribution Configuration**: Specifies how and where to distribute the built AMI
- **Image Pipeline**: Orchestrates the entire build process
- **Initial Image Build**: Triggers the first AMI build

## Features of the Built AMI

The resulting AMI includes:
- **Updated Amazon Linux 2023** with latest security patches
- **Apache HTTP Server** pre-installed and configured
- **Custom Welcome Page** with server information and real-time updates
- **Health Check Endpoint** at `/health`
- **Automatic Service Startup** - HTTP server starts automatically on boot
- **Security Configuration** - Firewall rules configured for HTTP traffic

## Web Service Details

The AMI includes a beautiful, responsive web interface that displays:
- Server status and information
- Instance metadata (ID, current time)
- Build information and components
- Service health status

The web service is accessible on port 80 and includes:
- Main page at `/`
- Health check endpoint at `/health`
- Automatic service management via systemd

## Prerequisites

1. **AWS CLI configured** with appropriate credentials
2. **Terraform installed** (version >= 1.0)
3. **AWS permissions** for:
   - EC2 Image Builder
   - IAM roles and policies
   - S3 bucket operations
   - VPC and security group management

## Quick Start

1. **Clone and navigate to the directory**:
   ```bash
   cd "04 EC2 Image Builder"
   ```

2. **Review and modify variables** in `terraform.tfvars`:
   ```hcl
   aws_region = "us-east-1"  # Change to your preferred region
   environment = "dev"
   instance_types = ["t3.medium"]
   ```

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Plan the deployment**:
   ```bash
   terraform plan
   ```

5. **Apply the configuration**:
   ```bash
   terraform apply
   ```

6. **Monitor the build process** in the AWS Console:
   - Go to EC2 Image Builder
   - Check the "Images" section for build progress
   - Build typically takes 15-30 minutes

## Configuration Options

### Region Configuration
Update the `aws_region` in `terraform.tfvars` and ensure the `parent_image` ARN matches your region.

### Instance Types
Modify `instance_types` in `terraform.tfvars` to use different instance sizes for building.

### Parent Image
The configuration uses Amazon Linux 2023. To use a different base image:
1. Find the appropriate ARN in the EC2 Image Builder console
2. Update the `parent_image` variable

### Custom Components
The web server component is defined in `main.tf`. You can modify it to:
- Install additional packages
- Configure different web servers (nginx, etc.)
- Add custom applications
- Modify the welcome page

## Build Pipeline

The pipeline includes:
1. **System Updates**: Updates all packages to latest versions
2. **Web Server Installation**: Installs Apache HTTP server
3. **Content Creation**: Creates a custom welcome page
4. **Service Configuration**: Enables and starts the web service
5. **Security Setup**: Configures firewall rules
6. **Health Checks**: Creates monitoring endpoints
7. **Validation**: Tests that all services are working correctly

## Scheduled Builds

The pipeline is configured to run daily at 2 AM UTC when there are dependency updates available. You can modify the schedule in the `aws_imagebuilder_image_pipeline` resource.

## Testing the Built AMI

After the build completes:

1. **Find your new AMI** in the EC2 console or use the build ARN from outputs
2. **Launch an EC2 instance** using the built AMI
3. **Ensure security group allows HTTP traffic** (port 80)
4. **Access the web service** at `http://[instance-public-ip]`
5. **Check health endpoint** at `http://[instance-public-ip]/health`

## Monitoring and Logs

- **Build logs** are stored in the created S3 bucket
- **Build status** can be monitored in the EC2 Image Builder console
- **CloudTrail** logs all Image Builder API calls

## Cost Considerations

- **Build instances** are terminated after each build
- **S3 storage** for logs (minimal cost)
- **AMI storage** in your account
- **EC2 instances** launched from the AMI (separate cost)

## Security Features

- **IAM roles** follow least privilege principle
- **S3 bucket** has encryption enabled
- **Security groups** are restrictive
- **System updates** are applied during build
- **No SSH access** required (uses SSM for management)

## Customization Examples

### Adding Node.js
Add to the component's build phase:
```yaml
- name: "InstallNodeJS"
  action: "ExecuteBash"
  inputs:
    commands:
      - "curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -"
      - "sudo yum install -y nodejs"
```

### Installing Docker
Add to the component's build phase:
```yaml
- name: "InstallDocker"
  action: "ExecuteBash"
  inputs:
    commands:
      - "sudo yum install -y docker"
      - "sudo systemctl enable docker"
      - "sudo usermod -a -G docker ec2-user"
```

## Troubleshooting

### Build Failures
1. Check CloudWatch logs for the build
2. Review S3 bucket logs
3. Verify IAM permissions
4. Check component syntax

### Network Issues
1. Verify VPC and subnet configuration
2. Check security group rules
3. Ensure internet gateway is attached

### Component Issues
1. Validate YAML syntax in components
2. Test commands manually on a test instance
3. Check for typos in file paths

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

**Note**: This will delete all created resources including any built AMIs and their snapshots.

## Additional Resources

- [EC2 Image Builder Documentation](https://docs.aws.amazon.com/imagebuilder/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Amazon Linux 2023 User Guide](https://docs.aws.amazon.com/linux/al2023/)
