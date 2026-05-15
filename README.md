# Lab M4.07 - Terraform AWS Networking
 
## Infrastructure Created
- **VPC:** 10.0.0.0/16 across 3 AZs
- **Public Subnets:** 3 (for load balancers)
- **Private Subnets:** 3 (for app servers)
- **Database Subnets:** 3 (for databases)
- **Internet Gateway:** 1
- **NAT Gateway:** 1 (configurable to 3)
 
## Architecture
 
\`\`\`
AZ-A          AZ-B          AZ-C
├─ Public     ├─ Public     ├─ Public
├─ Private    ├─ Private    ├─ Private
└─ Database   └─ Database   └─ Database
\`\`\`
 
## Deployment
 
\`\`\`bash
# Single NAT (dev)
terraform apply -var="single_nat_gateway=true"
 
# Multi-AZ NAT (prod)
terraform apply -var="single_nat_gateway=false"
\`\`\`
 
## Outputs
- VPC ID
- Subnet IDs (public, private, database)
- NAT Gateway public IPs
 
## Comparison: Manual vs Terraform
- **Manual (Week 3):** 45 minutes
- **Terraform:** 5 minutes