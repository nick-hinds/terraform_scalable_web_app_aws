# AWS Web Application Infrastructure with Terraform

### Exercise time: ~2.5-3 hrs

## 📋 Overview

This repository contains a production-ready, highly available web application infrastructure on AWS, built using **Terraform 1.14.3** with the latest features including native testing framework, enhanced validation, and improved lifecycle management.

### Architecture Highlights

- **Multi-AZ High Availability**: Resources deployed across 3 availability zones
- **Security-First Design**: KMS encryption, private subnets, security groups with least privilege
- **Auto-scaling**: Dynamic scaling based on demand with mixed instance policies
- **Cost Optimization**: Spot instances, S3 lifecycle policies, intelligent tiering
- **Observability**: CloudWatch dashboards, alarms, X-Ray tracing, and Synthetics
- **Infrastructure as Code**: Modular Terraform design with environment-specific configurations

## 🏗️ Architecture Components

### Network Layer
- **VPC**: Custom VPC with public, private, and database subnets across 3 AZs
- **NAT Gateways**: High availability with one per AZ (configurable for cost optimization)
- **VPC Endpoints**: For S3 and DynamoDB to reduce data transfer costs
- **Flow Logs**: Network traffic monitoring and security analysis

### Compute Layer
- **Application Load Balancer**: HTTP/HTTPS traffic distribution with health checks
- **Auto Scaling Group**: EC2 instances with dynamic scaling (2-10 instances)
- **Launch Template**: Standardized instance configuration with user data
- **Mixed Instances**: Support for spot and on-demand instances

### Data Layer
- **RDS PostgreSQL**: Multi-AZ deployment with automated backups
- **Read Replicas**: For production environments (optional)
- **S3 Buckets**: Static assets, logs, and ALB access logs
- **Secrets Manager**: Secure credential storage with automatic rotation

### Security Layer
- **KMS**: Encryption keys for all data at rest
- **Security Groups**: Layered security with strict ingress/egress rules
- **IAM Roles**: Least privilege access for all services
- **WAF**: Web Application Firewall for production (optional)
- **GuardDuty**: Threat detection (optional)

### Monitoring & Observability
- **CloudWatch Dashboards**: Real-time metrics visualization
- **CloudWatch Alarms**: Automated alerting for critical metrics
- **X-Ray**: Distributed tracing (production)
- **Synthetics**: Endpoint monitoring (production)
- **Cost Anomaly Detection**: Budget monitoring

### Content Delivery (Optional)
- **CloudFront CDN**: Global content distribution
- **Origin Access Identity**: Secure S3 access
- **Custom Error Pages**: User-friendly error handling

## 📁 Directory Structure

```
aws-terraform-infrastructure/
├── main.tf                 # Main orchestration file
├── variables.tf            # Input variables
├── locals.tf              # Computed local values
├── outputs.tf             # Output values
├── versions.tf            # Provider versions
├── cdn.tf                 # CloudFront configuration
├── terraform.tfvars.example  # Example variables file
├── environments/          # Environment-specific configs
│   ├── dev/
│   ├── staging/
│   └── prod/
└── modules/               # Reusable Terraform modules
    ├── vpc/               # Network infrastructure
    ├── security/          # Security resources
    ├── compute/           # ALB and Auto Scaling
    ├── database/          # RDS configuration
    ├── storage/           # S3 buckets
    └── monitoring/        # CloudWatch and alarms
```

## 🚀 Quick Start

### Prerequisites

1. **AWS Account**: With appropriate permissions
2. **Terraform**: Version 1.14.3 or higher
3. **AWS CLI**: Configured with credentials
4. **S3 Backend**: For state storage (optional but recommended)

### Installation

1. **Clone the repository**:
```bash
git clone <repository-url>
cd aws-terraform-infrastructure
```

2. **Copy and customize variables**:
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your configuration
```

3. **Initialize Terraform**:
```bash
# For development environment
terraform init -backend-config=environments/dev/backend.tfvars

# For production environment
terraform init -backend-config=environments/prod/backend.tfvars
```

4. **Review the plan**:
```bash
terraform plan -var-file=terraform.tfvars
```

5. **Apply the infrastructure**:
```bash
terraform apply -var-file=terraform.tfvars
```

## 📝 Configuration

### Essential Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `environment` | Environment name (dev/staging/prod) | - | Yes |
| `project_name` | Project identifier | `webapp` | No |
| `aws_region` | AWS region | `us-east-1` | No |
| `azs` | Availability zones (min 2, recommended 3) | 3 AZs | No |
| `instance_type` | EC2 instance type | `t3.medium` | No |
| `db_instance_class` | RDS instance class | `db.t3.medium` | No |
| `certificate_arn` | ACM certificate for HTTPS | - | No |
| `alert_email` | Email for CloudWatch alerts | - | No |

### Environment-Specific Configuration

Each environment can have its own configuration:

```hcl
# environments/prod/terraform.tfvars
environment                = "prod"
instance_type             = "t3.large"
min_size                  = 3
max_size                  = 20
db_instance_class         = "db.r6g.xlarge"
db_multi_az               = true
enable_deletion_protection = true
enable_cdn                = true
```

### Cost Optimization Settings

```hcl
# Enable cost optimization features
enable_cost_optimization = true  # Enables spot instances in non-prod
enable_spot_instances    = true  # Force spot instances
spot_max_price          = "0.05" # Maximum spot price
single_nat_gateway      = true   # Use single NAT (dev only)
```

## 🔒 Security Features

### Encryption
- **At Rest**: All data encrypted using AWS KMS
- **In Transit**: TLS/SSL for all communications
- **Secrets**: Stored in AWS Secrets Manager

### Network Security
- **Private Subnets**: Application and database tiers isolated
- **Security Groups**: Strict ingress/egress rules
- **NACLs**: Additional network layer protection
- **VPC Flow Logs**: Traffic monitoring and analysis

### Access Control
- **IAM Roles**: Service-specific roles with least privilege
- **Instance Profiles**: EC2 instances use IAM roles, not keys
- **MFA**: Recommended for production AWS account access

### Compliance & Monitoring
- **CloudTrail**: API audit logging (optional)
- **GuardDuty**: Threat detection (production)
- **Config**: Compliance monitoring (production)
- **WAF**: Web application firewall (production)

## 📊 Monitoring & Alerting

### CloudWatch Dashboards
- Application performance metrics
- Infrastructure health status
- Database performance
- Cost and usage tracking

### Alarms Configuration
- **CPU Utilization**: >80% triggers alert
- **Database Connections**: >80 connections
- **Unhealthy Targets**: Any unhealthy target
- **5XX Errors**: >10 errors in 5 minutes
- **Storage Space**: <10GB free space

### Log Aggregation
- Application logs in CloudWatch
- ALB access logs in S3
- VPC Flow Logs for network analysis
- RDS logs for database queries

## 💰 Cost Estimation

### Estimated Monthly Costs (US East 1)

| Environment | Compute | Database | Storage | Network | Total |
|-------------|---------|----------|---------|---------|-------|
| Development | $150 | $100 | $50 | $100 | ~$400 |
| Staging | $300 | $200 | $100 | $150 | ~$750 |
| Production | $600 | $800 | $200 | $400 | ~$2000 |

*Note: Costs vary based on usage and region*

### Cost Optimization Tips
1. Use spot instances for non-critical workloads
2. Enable S3 lifecycle policies
3. Right-size instances based on CloudWatch metrics
4. Use Reserved Instances for production
5. Clean up unused resources regularly

## 🧪 Testing

### Infrastructure Testing
```bash
# Validate Terraform configuration
terraform validate

# Format check
terraform fmt -check

# Security scanning with tfsec
tfsec .

# Cost estimation with Infracost
infracost breakdown --path .
```

## 🔧 Maintenance

### Regular Tasks
- **Weekly**: Review CloudWatch dashboards and costs
- **Monthly**: Update AMIs and patch instances
- **Quarterly**: Review and optimize resource sizing
- **Annually**: Review disaster recovery procedures

### Updating Infrastructure
```bash
# Update modules
terraform get -update

# Plan changes
terraform plan

# Apply with approval
terraform apply

# Rollback if needed
terraform plan -destroy
terraform destroy
```