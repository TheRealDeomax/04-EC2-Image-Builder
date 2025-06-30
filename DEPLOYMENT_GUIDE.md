# 🚀 EC2 Image Builder - Deployment Guide

## Overview
This guide walks you through deploying a complete EC2 Image Builder pipeline that creates a custom Amazon Linux AMI with web server capabilities.

## 📋 Pre-Deployment Checklist

### ✅ Prerequisites
- [ ] AWS CLI installed and configured
- [ ] Terraform installed (version >= 1.0)
- [ ] Valid AWS credentials with appropriate permissions
- [ ] Access to target AWS region

### ✅ Required AWS Permissions
Your AWS user/role needs these permissions:
- `EC2ImageBuilderFullAccess` (or equivalent custom policy)
- `IAMFullAccess` (for creating roles and policies)
- `EC2FullAccess` (for security groups and instances)
- `S3FullAccess` (if enabling logging)

## 🛠️ Step-by-Step Deployment

### Step 1: Prepare Configuration

1. **Review Variables** in `terraform.tfvars`:
   ```hcl
   # Basic settings
   aws_region   = "us-east-1"      # Your preferred region
   environment  = "dev"            # Environment name
   project_name = "web-server"     # Project identifier
   
   # Instance configuration
   instance_types = ["t3.micro", "t2.micro"]  # Free tier eligible
   
   # Base image (region-specific)
   parent_image_arn = "arn:aws:imagebuilder:us-east-1:aws:image/amazon-linux-2023-x86/x.x.x"
   
   # Optional features
   enable_logging  = true    # Enable S3 logging
   enable_schedule = false   # Disable automatic scheduling initially
   ```

2. **Customize for Your Region** (if not using us-east-1):
   - Update `aws_region` in terraform.tfvars
   - Find the correct `parent_image_arn` for your region in the EC2 Image Builder console

### Step 2: Deploy Infrastructure

1. **Initialize Terraform**:
   ```bash
   terraform init
   ```
   Expected output: "Terraform has been successfully initialized!"

2. **Validate Configuration**:
   ```bash
   terraform validate
   ```
   Expected output: "Success! The configuration is valid."

3. **Plan Deployment**:
   ```bash
   terraform plan
   ```
   Review the plan carefully. You should see ~15-20 resources to be created.

4. **Apply Configuration**:
   ```bash
   terraform apply
   ```
   Type `yes` when prompted. Deployment takes 2-3 minutes.

5. **Verify Outputs**:
   After successful deployment, you'll see important information including:
   - Pipeline ARN and name
   - Component ARNs
   - Next steps instructions

### Step 3: Build Your First AMI

1. **Access AWS Console**:
   - Navigate to EC2 Image Builder service
   - Go to "Image pipelines" section

2. **Find Your Pipeline**:
   - Look for pipeline named: `{project_name}-web-server-pipeline`
   - Default: `web-server-web-server-pipeline`

3. **Start Build Process**:
   - Select your pipeline
   - Click "Actions" → "Run pipeline"
   - Confirm by clicking "Run pipeline" in the dialog

4. **Monitor Progress**:
   - Build typically takes 15-30 minutes
   - Watch status in "Images" section
   - Status progression: Building → Testing → Distributing → Available

### Step 4: Verify Build Success

1. **Check Build Status**:
   - In EC2 Image Builder console, go to "Images"
   - Find your image with status "Available"
   - Note the AMI ID for testing

2. **View Build Logs** (if logging enabled):
   - Go to S3 console
   - Find bucket: `{project_name}-imagebuilder-logs-{random}`
   - Browse logs for detailed build information

### Step 5: Test Your Custom AMI

1. **Launch Test Instance**:
   - Go to EC2 console → "Launch Instance"
   - Click "My AMIs" tab
   - Select your custom AMI (named: `{project_name}-web-server-{build-date}`)
   - Choose instance type: t3.micro or t2.micro
   - Configure security group to allow HTTP traffic (port 80)

2. **Configure Security Group**:
   ```
   Type: HTTP
   Protocol: TCP
   Port: 80
   Source: 0.0.0.0/0 (or your IP for testing)
   ```

3. **Test Web Application**:
   - Wait for instance to reach "running" state
   - Copy public IP address
   - Open browser and navigate to: `http://[public-ip]`
   - You should see the custom web application

4. **Test Health Endpoint**:
   - Navigate to: `http://[public-ip]/health.html`
   - Should return JSON with service status

5. **Test SSM Connectivity**:
   - Go to Systems Manager console → Session Manager
   - Find your instance in the list
   - Click "Start session" to test remote access

## 🔧 Configuration Options

### Instance Type Changes

**For Production (Higher Performance)**:
```hcl
instance_types = ["t3.medium", "m5.large"]
```

**For Cost Optimization (Free Tier)**:
```hcl
instance_types = ["t3.micro", "t2.micro"]
```

### Enable Automated Builds

```hcl
enable_schedule = true
schedule_expression = "cron(0 2 * * sun)"  # Weekly on Sunday 2 AM
```

### Multi-Region Deployment

Update `main.tf` distribution configuration:
```hcl
distribution {
  region = "us-east-1"
  # ... configuration
}
distribution {
  region = "us-west-2"
  # ... configuration  
}
```

## 🚨 Troubleshooting

### Common Issues and Solutions

#### Build Fails During System Update
**Problem**: DNF/YUM update errors
**Solution**: 
- Check CloudWatch logs for specific package errors
- Verify internet connectivity from build subnet
- Ensure security group allows outbound HTTPS (port 443)

#### SSM Agent Installation Fails
**Problem**: SSM package not found
**Solution**:
- Verify the base image includes SSM agent
- Check that the instance has internet access
- Review IAM permissions for SSM

#### Web Server Not Accessible
**Problem**: Can't reach web application
**Solution**:
- Verify security group allows inbound HTTP (port 80)
- Check that Apache service started successfully
- Review build logs for Apache installation errors

#### Pipeline Not Found in Console
**Problem**: Can't see pipeline after terraform apply
**Solution**:
- Verify you're in the correct AWS region
- Check IAM permissions for EC2 Image Builder
- Confirm terraform apply completed successfully

### Getting Detailed Logs

1. **CloudWatch Logs**:
   - Service: EC2 Image Builder
   - Log groups: `/aws/imagebuilder/image`

2. **S3 Logs** (if enabled):
   - Bucket: `{project_name}-imagebuilder-logs-{random}`
   - Prefix: `image-builder-logs/`

3. **Terraform Debug**:
   ```bash
   export TF_LOG=DEBUG
   terraform apply
   ```

## 📊 Monitoring and Maintenance

### Regular Tasks

1. **Monitor Build Status**:
   - Check EC2 Image Builder console weekly
   - Review failed builds and logs

2. **Update Base Images**:
   - Periodically update `parent_image_arn` to latest versions
   - Test new base images in development first

3. **Review Costs**:
   - Monitor EC2 and S3 charges
   - Consider instance type optimization

4. **Security Updates**:
   - Custom AMIs include latest patches at build time
   - Schedule regular rebuilds for security updates

### Automated Monitoring

Set up CloudWatch alarms for:
- Build failures
- Unexpected costs
- S3 bucket size (if logging enabled)

## 🧹 Cleanup

### Remove Test Resources
```bash
# Remove test EC2 instances manually through console
# or use AWS CLI:
aws ec2 terminate-instances --instance-ids i-1234567890abcdef0
```

### Remove All Infrastructure
```bash
terraform destroy
```
**Warning**: This removes ALL resources including:
- Image Builder pipeline and components
- IAM roles and policies
- Security groups
- S3 bucket and logs
- Custom AMIs (unless protected)

### Partial Cleanup
To keep AMIs but remove pipeline:
```bash
# Comment out pipeline resource in main.tf
terraform apply
```

## 📈 Next Steps

### Production Deployment
1. Enable automated scheduling
2. Set up CloudWatch monitoring
3. Implement multi-region distribution
4. Add custom components for your applications

### Advanced Features
1. **Custom Components**: Add Docker, Node.js, or other software
2. **Testing**: Implement custom test components
3. **Security**: Add vulnerability scanning components
4. **Compliance**: Add hardening and compliance checks

### Integration
1. **CI/CD**: Integrate with your deployment pipeline
2. **Auto Scaling**: Use custom AMIs with Auto Scaling Groups
3. **Load Balancers**: Deploy behind Application Load Balancer
4. **Monitoring**: Integrate with CloudWatch, Datadog, etc.

---

**🎉 Congratulations! You now have a fully automated AMI building pipeline using EC2 Image Builder.**
