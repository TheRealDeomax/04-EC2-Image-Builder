# Deployment Guide

## Step-by-Step Deployment Instructions

### 1. Prerequisites Setup

Before deploying, ensure you have:

```powershell
# Check AWS CLI is configured
aws sts get-caller-identity

# Check Terraform is installed
terraform version

# Should return version >= 1.0
```

### 2. Configure Variables

Edit `terraform.tfvars` to match your requirements:

```hcl
# Required: Change to your preferred region
aws_region = "us-east-1"

# Environment tag
environment = "dev"

# Instance types for building (can use multiple)
instance_types = ["t3.medium"]

# Optional: Key pair name for SSH access to instances launched from AMI
# key_pair_name = "my-key-pair"

# Optional: Enable Auto Scaling Group
# create_auto_scaling = true
# asg_min_size = 1
# asg_max_size = 3
# asg_desired_capacity = 2
```

### 3. Initialize and Deploy

```powershell
# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Deploy the infrastructure
terraform apply
```

### 4. Monitor the Build Process

1. **Open AWS Console** → EC2 Image Builder
2. **Navigate to Images** → Check build status
3. **Build time**: Typically 15-30 minutes
4. **Monitor logs** in the created S3 bucket

### 5. Test the Built AMI

Once the build completes:

#### Option A: Use Launch Template (if enabled)
```powershell
# Get the launch template ID from Terraform output
terraform output launch_template_id

# Launch instance via AWS CLI
aws ec2 run-instances --launch-template LaunchTemplateId=lt-xxxxxxxxx
```

#### Option B: Manual Launch
1. **Find your AMI** in EC2 Console → AMIs
2. **Launch instance** with security group allowing HTTP (port 80)
3. **Get public IP** and test

#### Option C: Use Validation Script
```powershell
# Get the instance public IP and run validation
.\validate-ami.ps1 -InstanceIP "52.23.45.67"
```

### 6. Verify Web Service

Access your instance:
- **Main page**: `http://[instance-ip]`
- **Health check**: `http://[instance-ip]/health`

Expected response:
- Beautiful welcome page with instance information
- Health endpoint returning "OK"
- Real-time updates showing current time and metadata

## Advanced Configuration

### Custom Components

To modify the web server setup, edit the `aws_imagebuilder_component` resource in `main.tf`:

```hcl
# Example: Add Node.js
{
  name   = "InstallNodeJS"
  action = "ExecuteBash"
  inputs = {
    commands = [
      "curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -",
      "sudo yum install -y nodejs npm"
    ]
  }
}
```

### Regional Deployment

To deploy in different regions:

1. **Update terraform.tfvars**:
   ```hcl
   aws_region = "eu-west-1"
   ```

2. **Update parent image ARN** for the new region:
   ```hcl
   parent_image = "arn:aws:imagebuilder:eu-west-1:aws:image/amazon-linux-2023-x86/x.x.x"
   ```

### Automated Builds

The pipeline includes a daily schedule. To modify:

```hcl
schedule {
  schedule_expression = "cron(0 6 * * ? *)"  # 6 AM daily
  pipeline_execution_start_condition = "EXPRESSION_MATCH_AND_DEPENDENCY_UPDATES_AVAILABLE"
}
```

### High Availability Setup

Enable Auto Scaling Group:

```hcl
# In terraform.tfvars
create_auto_scaling = true
asg_min_size = 2
asg_max_size = 6
asg_desired_capacity = 3
```

## Troubleshooting

### Build Failures

1. **Check build logs**:
   ```powershell
   # Get S3 bucket name
   terraform output s3_logs_bucket
   
   # Browse logs in AWS Console or CLI
   aws s3 ls s3://[bucket-name]/image-builder-logs/
   ```

2. **Common issues**:
   - **Network connectivity**: Check VPC/subnet configuration
   - **IAM permissions**: Verify roles have required policies
   - **Component syntax**: Validate YAML in custom components

### Instance Launch Issues

1. **Security groups**: Ensure HTTP (port 80) is allowed
2. **Key pairs**: Verify key pair exists if specified
3. **AMI availability**: Check AMI is in "available" state

### Web Service Issues

1. **Service not running**:
   ```bash
   # SSH to instance and check
   sudo systemctl status httpd
   sudo systemctl start httpd
   ```

2. **Firewall blocking**:
   ```bash
   # Check iptables rules
   sudo iptables -L
   ```

## Cost Optimization

### Build Costs
- Use smaller instance types for building: `t3.small` or `t3.micro`
- Schedule builds only when needed
- Clean up old AMIs regularly

### Runtime Costs
- Use appropriate instance sizes for your workload
- Implement Auto Scaling for variable loads
- Use Spot instances for development environments

## Security Best Practices

1. **Restrict SSH access**:
   ```hcl
   # In launch-template.tf security group
   cidr_blocks = ["YOUR.IP.ADDRESS/32"]  # Instead of 0.0.0.0/0
   ```

2. **Regular updates**:
   - Enable automated pipeline runs
   - Monitor security patches
   - Update base images regularly

3. **Monitoring**:
   - Enable CloudWatch logs
   - Set up alerting for failed builds
   - Monitor instance health

## Cleanup

To remove all resources:

```powershell
# Destroy everything
terraform destroy

# Confirm with 'yes' when prompted
```

**Warning**: This will delete:
- All EC2 Image Builder resources
- Built AMIs and snapshots
- S3 bucket and logs
- IAM roles and policies
- Any running instances (if using Auto Scaling)

## Next Steps

1. **Customize the web application** for your specific needs
2. **Add SSL/TLS support** with certificates
3. **Integrate with load balancers** for production
4. **Set up monitoring and alerting**
5. **Implement CI/CD pipeline** for automated deployments
