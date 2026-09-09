# Terraform — RHEL EC2 lab servers

Provisions 10 RHEL EC2 instances (t3.small, 20GB gp3 root disk), reachable by SSH key.

By default, instances are spread across all subnets of the account's default VPC. To use a specific existing VPC/subnet instead, set `vpc_id` and/or `subnet_id` (see `terraform.tfvars.example`) — that VPC/subnet must already have an Internet Gateway and a route table with a `0.0.0.0/0` route, or the instances won't be reachable over SSH even though the security group allows it.

## Usage

```bash
cd terraform
terraform init

cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: fill in ssh_public_key_path, and either fill in the
# credential vars there or export them instead (recommended):
export TF_VAR_aws_access_key="..."
export TF_VAR_aws_secret_key="..."
export TF_VAR_aws_session_token="..."   # only if using temporary/STS credentials
export TF_VAR_aws_account_id="..."      # optional safety check
export TF_VAR_ssh_public_key_path="../keys/github-workshop.pub"

terraform plan
terraform apply
```

SSH into an instance using the private key that matches `ssh_public_key_path`:

```bash
ssh -i ../keys/github-workshop ec2-user@$(terraform output -json instance_public_ips | jq -r '.[0]')
```

Build an Ansible inventory from `terraform output -json ansible_inventory_map` (instance name → public IP).

Tear down the lab with `terraform destroy`.

## IAM permissions

`iam-policy-example.json` is a least-privilege policy covering exactly what this code does (AMI/VPC/subnet/security-group lookups, plus creating the key pair, security group, and instances). Attach it to whichever IAM user or role supplies the credentials above.
