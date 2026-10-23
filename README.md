[README.md](https://github.com/user-attachments/files/33876339/README.md)
# Terraform private web application (Sydney)

Creates a single-AZ VPC with public and private subnets, an internet gateway,
a NAT Gateway, a private Ubuntu EC2 instance running Nginx, and an internet-facing
Network Load Balancer.

## Before running

- Verify the AMI ID in `terraform.tfvars` is still available in `ap-southeast-2`.
- Confirm AWS Organizations SCP and IAM permissions allow all required resource
  operations.
- NAT Gateways, Elastic IPs, and Network Load Balancers can incur charges.

## Commands

```bash
terraform init
terraform fmt
terraform validate
terraform plan
```

Review the plan and account permissions before considering `terraform apply`.

## Files

- `main.tf`: provider, variables, networking, EC2, NLB, and outputs
- `terraform.tfvars`: region-specific AMI and Availability Zone
- `.gitignore`: excludes Terraform state and local files
