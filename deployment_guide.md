# Deployment Guide

## Prerequisites Checklist

- [ ] AWS Account with appropriate permissions
- [ ] AWS CLI installed and configured
- [ ] Terraform 1.14.3+ installed
- [ ] Git installed
- [ ] Text editor (VS Code, Vim, etc.)

## Step-by-Step Deployment

### 1. AWS Account Setup

```bash
# Configure AWS CLI
aws configure
# Enter: Access Key ID, Secret Access Key, Region, Output format

# Verify credentials
aws sts get-caller-identity
```

### 2. Clone and Configure

```bash
# Clone the repository
git clone <repository-url>
cd aws-terraform-infrastructure

# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit with your settings
vi terraform.tfvars
```

### 3. Environment Selection

For **Development**:
```bash
export ENV=dev
terraform init -backend-config=environments/dev/backend.tfvars
```

For **Staging**:
```bash
export ENV=staging
terraform init -backend-config=environments/staging/backend.tfvars
```

For **Production**:
```bash
export ENV=prod
terraform init -backend-config=environments/prod/backend.tfvars
```

### 4. Deploy Infrastructure

```bash
# Review the plan
terraform plan -var environment=$ENV

# Apply if everything looks correct
terraform apply -var environment=$ENV

# Save outputs
terraform output -json > outputs.json
```

### 5. Post-Deployment Verification

```bash
# Get ALB DNS
ALB_DNS=$(terraform output -raw alb_dns_name)

# Test health endpoint
curl -f http://$ALB_DNS/health || echo "Health check failed"

# Check CloudWatch Dashboard
echo "Dashboard URL: $(terraform output -raw cloudwatch_dashboard_url)"
```

## Environment-Specific Configurations

### Development Environment

```hcl
# environments/dev/terraform.tfvars
environment                = "dev"
instance_type             = "t3.small"
min_size                  = 1
max_size                  = 3
desired_capacity          = 2
db_instance_class         = "db.t3.micro"
db_multi_az              = false
enable_deletion_protection = false
enable_cost_optimization  = true
```

### Production Environment

```hcl
# environments/prod/terraform.tfvars
environment                = "prod"
instance_type             = "t3.large"
min_size                  = 3
max_size                  = 20
desired_capacity          = 5
db_instance_class         = "db.r6g.xlarge"
db_multi_az              = true
enable_deletion_protection = true
enable_cdn                = true
enable_waf               = true
```

## SSL/TLS Setup

### Request ACM Certificate

```bash
# Request certificate
aws acm request-certificate \
  --domain-name example.com \
  --subject-alternative-names "*.example.com" \
  --validation-method DNS

# Get certificate ARN
aws acm list-certificates

# Add to terraform.tfvars
certificate_arn = "arn:aws:acm:region:account:certificate/id"
```

## Database Access

### Connect to RDS

```bash
# Get database endpoint
DB_ENDPOINT=$(terraform output -raw db_instance_endpoint | cut -d: -f1)

# Get password from Secrets Manager
SECRET_ARN=$(terraform output -raw db_secret_arn)
DB_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id $SECRET_ARN \
  --query SecretString \
  --output text | jq -r .password)

# Connect using psql
psql -h $DB_ENDPOINT -U dbadmin -d webappdb
```

## Monitoring Setup

### Enable Alerting

```bash
# Add alert email
echo 'alert_email = "team@example.com"' >> terraform.tfvars

# Apply changes
terraform apply -var environment=$ENV
```

### Access Dashboards

```bash
# CloudWatch Dashboard
terraform output cloudwatch_dashboard_url

# Application Logs
aws logs tail /aws/ec2/webapp-$ENV --follow
```

## Cost Management

### Enable Cost Alerts

```bash
# Create budget alert
aws budgets create-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget file://budget.json \
  --notifications-with-subscribers file://notifications.json
```

### Review Costs

```bash
# Get current month costs
aws ce get-cost-and-usage \
  --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --group-by Type=DIMENSION,Key=SERVICE
```

## Troubleshooting

### Common Issues and Solutions

**Issue**: Subnet conflicts
```bash
# Solution: Change VPC CIDR in terraform.tfvars
vpc_cidr = "10.1.0.0/16"
```

**Issue**: Insufficient capacity
```bash
# Solution: Try different instance types
instance_types_override = ["t3.medium", "t3a.medium", "t2.medium"]
```

**Issue**: RDS storage full
```bash
# Solution: Increase storage
terraform apply -var db_allocated_storage=200
```

## Cleanup

### Destroy Resources

```bash
# Remove all resources
terraform destroy -var environment=$ENV

# Confirm by typing 'yes'
```

### Manual Cleanup

```bash
# Delete S3 buckets with versioning
aws s3 rm s3://bucket-name --recursive
aws s3api delete-bucket --bucket bucket-name

# Delete CloudWatch Logs
aws logs delete-log-group --log-group-name /aws/ec2/webapp-$ENV
```

## Backup and Recovery

### Create Backup

```bash
# Create RDS snapshot
aws rds create-db-snapshot \
  --db-instance-identifier webapp-$ENV-db \
  --db-snapshot-identifier webapp-$ENV-backup-$(date +%Y%m%d)

# Backup Terraform state
aws s3 cp s3://terraform-state-bucket/terraform.tfstate \
  s3://backup-bucket/terraform-backup-$(date +%Y%m%d).tfstate
```

### Restore from Backup

```bash
# Restore RDS from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier webapp-$ENV-db-restored \
  --db-snapshot-identifier webapp-$ENV-backup-20240101

# Restore Terraform state
aws s3 cp s3://backup-bucket/terraform-backup-20240101.tfstate \
  s3://terraform-state-bucket/terraform.tfstate
```

## Security Hardening

### Enable GuardDuty

```bash
# In terraform.tfvars
enable_guardduty = true
```

### Enable WAF

```bash
# In terraform.tfvars
enable_waf = true
```

### Rotate Secrets

```bash
# Rotate RDS password
aws secretsmanager rotate-secret \
  --secret-id $(terraform output -raw db_secret_arn) \
  --rotation-lambda-arn arn:aws:lambda:region:account:function:rotation
```

---

**Support Contact**: DevOps Team - devops@example.com
**Documentation**: https://wiki.example.com/terraform
**Emergency**: On-call rotation - PagerDuty