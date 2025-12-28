#!/bin/bash
# Create environment-specific directories
mkdir -p environments/{dev,staging,prod}

# Create backend configurations
cat > environments/dev/backend.tfvars <<EOF
bucket         = "your-terraform-state-bucket-dev"
key            = "infrastructure/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "terraform-state-lock-dev"
EOF

cat > environments/staging/backend.tfvars <<EOF
bucket         = "your-terraform-state-bucket-staging"
key            = "infrastructure/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "terraform-state-lock-staging"
EOF

cat > environments/prod/backend.tfvars <<EOF
bucket         = "your-terraform-state-bucket-prod"
key            = "infrastructure/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "terraform-state-lock-prod"
EOF
