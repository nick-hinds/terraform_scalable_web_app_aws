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
├── deployment_guide.md    # Detailed deployment instructions
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

## 🚀 Deployment Guide

### Prerequisites Checklist

- [ ] AWS Account with appropriate permissions
- [ ] AWS CLI installed and configured (`aws configure`)
- [ ] Terraform 1.14.3+ installed
- [ ] Git installed
- [ ] S3 Backend for state storage (recommended)

### Quick Deployment Steps

**1. Configure AWS Credentials**
```bash
# Configure AWS CLI
aws configure
# Verify: aws sts get-caller-identity
```

**2. Clone and Setup**
```bash
git clone <repository-url>
cd aws-terraform-infrastructure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your configuration
```

**3. Select Environment and Initialize**
```bash
# Development
export ENV=dev
terraform init -backend-config=environments/dev/backend.tfvars

# Staging
export ENV=staging
terraform init -backend-config=environments/staging/backend.tfvars

# Production
export ENV=prod
terraform init -backend-config=environments/prod/backend.tfvars
```

**4. Deploy Infrastructure**
```bash
# Review planned changes
terraform plan -var environment=$ENV

# Apply infrastructure
terraform apply -var environment=$ENV

# Save outputs for reference
terraform output -json > outputs.json
```

**5. Post-Deployment Verification**
```bash
# Test the application load balancer
ALB_DNS=$(terraform output -raw alb_dns_name)
curl -f http://$ALB_DNS/health

# Access CloudWatch Dashboard
echo "Dashboard: $(terraform output -raw cloudwatch_dashboard_url)"
```

### Environment-Specific Configurations

**Development Environment**
```hcl
# environments/dev/terraform.tfvars
environment                = "dev"
instance_type             = "t3.small"
min_size                  = 1
max_size                  = 3
db_instance_class         = "db.t3.micro"
db_multi_az              = false
enable_cost_optimization  = true
single_nat_gateway        = true  # Cost savings
```

**Production Environment**
```hcl
# environments/prod/terraform.tfvars
environment                = "prod"
instance_type             = "t3.large"
min_size                  = 3
max_size                  = 20
db_instance_class         = "db.r6g.xlarge"
db_multi_az              = true
enable_deletion_protection = true
enable_cdn                = true
enable_waf               = true
```

### SSL/TLS Setup (Optional)

```bash
# Request ACM Certificate
aws acm request-certificate \
  --domain-name example.com \
  --subject-alternative-names "*.example.com" \
  --validation-method DNS

# Add certificate ARN to terraform.tfvars
certificate_arn = "arn:aws:acm:region:account:certificate/id"
```

### Database Access

```bash
# Get database connection details
DB_ENDPOINT=$(terraform output -raw db_instance_endpoint | cut -d: -f1)
SECRET_ARN=$(terraform output -raw db_secret_arn)

# Retrieve password from Secrets Manager
DB_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id $SECRET_ARN \
  --query SecretString \
  --output text | jq -r .password)

# Connect to database
psql -h $DB_ENDPOINT -U dbadmin -d webappdb
```

### Cleanup

```bash
# Destroy all resources
terraform destroy -var environment=$ENV

# Manual cleanup if needed
aws s3 rm s3://bucket-name --recursive
aws s3api delete-bucket --bucket bucket-name
```

> **Note**: For detailed deployment instructions, troubleshooting, backup procedures, and security hardening steps, see [deployment_guide.md](deployment_guide.md)

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
- **Secrets**: Stored in AWS Secrets Manager with rotation

### Network Security
- **Private Subnets**: Application and database tiers isolated
- **Security Groups**: Strict ingress/egress rules with least privilege
- **VPC Flow Logs**: Traffic monitoring and security analysis

### Access Control
- **IAM Roles**: Service-specific roles with least privilege
- **Instance Profiles**: EC2 instances use IAM roles, not access keys
- **MFA**: Recommended for production AWS account access

### Compliance & Monitoring
- **CloudTrail**: API audit logging (optional)
- **GuardDuty**: Intelligent threat detection (production)
- **Config**: Resource compliance monitoring (production)
- **WAF**: Web application firewall protection (production)

## 📊 Monitoring & Alerting

### CloudWatch Dashboards
- Application performance and health metrics
- Infrastructure resource utilization
- Database performance and connections
- Cost tracking and usage patterns

### Configured Alarms
- **CPU Utilization**: Alert when >80%
- **Database Connections**: Alert when >80 connections
- **Unhealthy Targets**: Immediate alert for any unhealthy instances
- **5XX Errors**: Alert when >10 errors in 5 minutes
- **Storage Space**: Alert when <10GB free space

### Monitoring Setup

```bash
# Enable email alerts
echo 'alert_email = "team@example.com"' >> terraform.tfvars
terraform apply -var environment=$ENV

# View application logs
aws logs tail /aws/ec2/webapp-$ENV --follow
```

## 💰 Cost Estimation

### Estimated Monthly Costs (US East 1)

| Environment | Compute | Database | Storage | Network | Total |
|-------------|---------|----------|---------|---------|-------|
| Development | $150 | $100 | $50 | $100 | ~$400 |
| Staging | $300 | $200 | $100 | $150 | ~$750 |
| Production | $600 | $800 | $200 | $400 | ~$2000 |

*Note: Actual costs vary based on usage patterns, data transfer, and region*

### Cost Optimization Tips
1. Enable spot instances for non-critical dev/staging environments
2. Use S3 lifecycle policies for log rotation and archival
3. Right-size instances based on CloudWatch metrics
4. Purchase Reserved Instances or Savings Plans for production
5. Regularly review and clean up unused resources
6. Use single NAT gateway in development (enable `single_nat_gateway = true`)

## 🧪 Testing & Validation

```bash
# Validate Terraform configuration
terraform validate

# Format check
terraform fmt -check

# Security scanning
tfsec .

# Cost estimation
infracost breakdown --path .

# Plan review before apply
terraform plan -out=tfplan
terraform show tfplan
```

## 🔧 Maintenance & Operations

### Regular Maintenance Tasks
- **Weekly**: Review CloudWatch dashboards and cost reports
- **Monthly**: Update AMIs and apply security patches
- **Quarterly**: Review and optimize resource sizing
- **Annually**: Test disaster recovery procedures

### Infrastructure Updates
```bash
# Update Terraform modules
terraform get -update

# Review and apply changes
terraform plan
terraform apply

# Rollback if needed
terraform destroy
```

### Backup & Recovery

```bash
# Create RDS snapshot
aws rds create-db-snapshot \
  --db-instance-identifier webapp-$ENV-db \
  --db-snapshot-identifier webapp-$ENV-backup-$(date +%Y%m%d)

# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier webapp-$ENV-db-restored \
  --db-snapshot-identifier webapp-$ENV-backup-YYYYMMDD
```

## 🆘 Troubleshooting

### Common Issues

**Subnet CIDR conflicts**
```bash
# Change VPC CIDR in terraform.tfvars
vpc_cidr = "10.1.0.0/16"
```

**Insufficient EC2 capacity**
```bash
# Add multiple instance type options
instance_types_override = ["t3.medium", "t3a.medium", "t2.medium"]
```

**RDS storage full**
```bash
# Increase allocated storage
terraform apply -var db_allocated_storage=200
```
