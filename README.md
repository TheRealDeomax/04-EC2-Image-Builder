# EC2 Image Builder Pipeline - Complete Implementation

## 📋 Overview

This Terraform configuration creates a complete EC2 Image Builder pipeline following AWS best practices and official documentation. It builds a custom Amazon Linux AMI with a web server, SSM agent, and all necessary security configurations.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    EC2 Image Builder Pipeline                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐    ┌──────────────────┐    ┌─────────────┐ │
│  │   Components    │    │   Image Recipe   │    │ Pipeline    │ │
│  │                 │    │                  │    │             │ │
│  │ • System Update │───▶│ • Base Image     │───▶│ • Build     │ │
│  │ • SSM Agent     │    │ • Components     │    │ • Test      │ │
│  │ • Web Server    │    │ • Configuration  │    │ • Distribute│ │
│  └─────────────────┘    └──────────────────┘    └─────────────┘ │
│                                                                 │
│  ┌─────────────────┐    ┌──────────────────┐    ┌─────────────┐ │
│  │ Infrastructure  │    │  Distribution    │    │   Outputs   │ │
│  │                 │    │                  │    │             │ │
│  │ • IAM Roles     │    │ • AMI Tags       │    │ • Custom    │ │
│  │ • Security Grps │    │ • Target Regions │    │   AMI       │ │
│  │ • Instance Types│    │ • Permissions    │    │ • Metadata  │ │
│  └─────────────────┘    └──────────────────┘    └─────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## 🎯 What This Creates

### Core Infrastructure
- **IAM Roles & Policies**: Proper permissions for Image Builder service and instances
- **Security Groups**: Network access controls for build instances
- **S3 Bucket**: Secure storage for build logs (optional)

### Image Builder Resources
- **3 Custom Components**: System updates, SSM agent, web server
- **Image Recipe**: Combines base Amazon Linux 2023 with custom components
- **Infrastructure Configuration**: Defines build environment and instance types
- **Distribution Configuration**: Specifies AMI creation and tagging
- **Image Pipeline**: Orchestrates the entire build process

### Built AMI Features
- ✅ **Latest Amazon Linux 2023** with security updates
- ✅ **Amazon SSM Agent** for remote management
- ✅ **Apache HTTP Server** with auto-start configuration
- ✅ **Modern Web Application** with responsive design
- ✅ **Health Check Endpoints** for monitoring
- ✅ **Comprehensive Testing** during build process

## 🚀 Quick Start

### Prerequisites
1. **AWS CLI** configured with appropriate credentials
2. **Terraform** installed (version >= 1.0)
3. **Appropriate AWS permissions** (see permissions section below)

### Deployment Steps

1. **Initialize Terraform**:
   ```bash
   terraform init
   ```

2. **Review Configuration**:
   ```bash
   terraform plan
   ```

3. **Deploy Infrastructure**:
   ```bash
   terraform apply
   ```

4. **Start Image Build**:
   - Go to AWS Console → EC2 Image Builder
   - Navigate to "Image pipelines"
   - Find your pipeline and click "Actions" → "Run pipeline"
   - Monitor progress (typically 15-30 minutes)

5. **Test Your AMI**:
   - Launch EC2 instance using the new AMI
   - Access web application at `http://[instance-public-ip]`

## ⚙️ Configuration

### Variables (`terraform.tfvars`)

```hcl
# Basic Configuration
aws_region   = "us-east-1"
environment  = "dev"
project_name = "web-server"

# Instance Types (Free Tier Eligible)
instance_types = ["t3.micro", "t2.micro"]

# Base Image
parent_image_arn = "arn:aws:imagebuilder:us-east-1:aws:image/amazon-linux-2023-x86/x.x.x"

# Optional Features
enable_logging  = true   # S3 logging
enable_schedule = false  # Automated builds
```

### Customization Options

#### Change Instance Types
For faster builds (non-free tier):
```hcl
instance_types = ["t3.medium", "t3.large"]
```

#### Enable Scheduled Builds
```hcl
enable_schedule = true
schedule_expression = "cron(0 2 * * sun)"  # Weekly on Sunday 2 AM
```

#### Different Base Image
Find ARNs in EC2 Image Builder console:
```hcl
parent_image_arn = "arn:aws:imagebuilder:us-west-2:aws:image/ubuntu-server-20-lts-x86/x.x.x"
```

## 🔧 Components Details

### 1. System Update Component
- Updates all system packages using `dnf` (Amazon Linux 2023) or `yum`
- Handles different Linux distributions automatically
- Includes validation steps

### 2. SSM Agent Component  
- Installs latest Amazon SSM Agent
- Configures automatic startup
- Verifies service is running
- Enables remote management capabilities

### 3. Web Server Component
- Installs Apache HTTP Server
- Creates modern, responsive web application
- Sets up health check endpoints
- Configures proper file permissions
- Tests all services during build

## 🌐 Web Application Features

The built AMI includes a professional web application:

- **Modern Design**: Responsive layout with gradient background
- **Server Information**: OS details, build date, installed features
- **Status Dashboard**: Service health and system information
- **Health Endpoints**: `/health.html` for monitoring
- **Mobile Friendly**: Optimized for all screen sizes

## 🔐 Security & Permissions

### Required AWS Permissions
Your AWS credentials need permissions for:
- EC2 Image Builder (full access)
- IAM (create roles and policies)
- EC2 (security groups, instances)
- S3 (bucket operations, if logging enabled)

### Security Features
- **Least Privilege IAM**: Minimal required permissions
- **Network Security**: Restrictive security groups
- **Encryption**: S3 bucket encryption enabled
- **No SSH Access**: Uses SSM for secure remote access

## 💰 Cost Considerations

### Free Tier Eligible
- **Build Instances**: t3.micro/t2.micro (750 hours/month free)
- **S3 Storage**: 5GB free tier for logs
- **Network**: Standard data transfer rates

### Estimated Costs (if exceeding free tier)
- **Build Instance**: ~$0.0104/hour (t3.micro)
- **Build Duration**: 15-30 minutes per build
- **Storage**: AMI snapshots (~$0.05/GB/month)

## 📊 Monitoring & Troubleshooting

### Build Monitoring
1. **AWS Console**: EC2 Image Builder → Images
2. **CloudWatch Logs**: Detailed build logs
3. **S3 Logs**: Comprehensive build artifacts (if enabled)

### Common Issues
- **Build Failures**: Check CloudWatch logs for specific errors
- **Permission Errors**: Verify IAM roles and policies
- **Network Issues**: Check security group and VPC configuration
- **Component Errors**: Review YAML syntax and command execution

### Validation Steps
Each component includes validation to ensure:
- Services are running correctly
- Dependencies are installed
- Web application is accessible
- Health checks pass

## 🔄 Pipeline Workflow

1. **Trigger**: Manual or scheduled execution
2. **Launch**: EC2 instance with base AMI
3. **Build**: Execute components in sequence:
   - Update system packages
   - Install and configure SSM Agent
   - Install and configure web server
4. **Test**: Run validation tests
5. **Create**: Generate AMI with proper tags
6. **Distribute**: Make AMI available in specified regions
7. **Cleanup**: Terminate build instance

## 📚 File Structure

```
├── main.tf              # Core infrastructure and Image Builder resources
├── variables.tf         # Variable definitions with validation
├── outputs.tf          # Output values and next steps
├── terraform.tfvars    # Configuration values
└── README.md           # This documentation
```

## 🎉 Success Indicators

After successful deployment and build:

1. ✅ **Pipeline Created**: Visible in EC2 Image Builder console
2. ✅ **Build Completes**: Status shows "Available"
3. ✅ **AMI Generated**: Custom AMI appears in EC2 AMIs
4. ✅ **Web App Works**: Accessible at instance public IP
5. ✅ **SSM Connected**: Instance appears in Systems Manager

## 🔧 Advanced Usage

### Custom Components
Add your own components by creating additional `aws_imagebuilder_component` resources and including them in the recipe.

### Multi-Region Distribution
Modify the distribution configuration to include multiple regions:

```hcl
distribution {
  region = "us-east-1"
  # ... ami configuration
}
distribution {
  region = "us-west-2"  
  # ... ami configuration
}
```

### Automated Testing
Enable comprehensive testing with custom test components for your specific applications.

## 📞 Support

For issues or questions:
1. Check AWS Image Builder documentation
2. Review CloudWatch logs for build details
3. Validate IAM permissions
4. Ensure VPC and networking configuration

---

**🎯 This implementation follows AWS best practices and provides a solid foundation for automated AMI building with EC2 Image Builder.**
