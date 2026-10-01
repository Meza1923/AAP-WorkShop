### AWS credentials / account ###

variable "aws_access_key" {
  description = "AWS access key ID used to authenticate the provider."
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS secret access key used to authenticate the provider."
  type        = string
  sensitive   = true
}

variable "aws_session_token" {
  description = "AWS temporary session token (STS), if using temporary/assumed-role credentials. Leave empty for long-lived IAM user credentials."
  type        = string
  sensitive   = true
  default     = ""
}

variable "aws_region" {
  description = "AWS region to deploy the instances into."
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "Expected AWS account ID. If set, deployment is aborted if the supplied credentials belong to a different account. Leave empty to skip the check."
  type        = string
  default     = ""
}

### Instance sizing / count ###

variable "instance_count" {
  description = "Number of RHEL EC2 instances to create."
  type        = number
  default     = 10

  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 50
    error_message = "instance_count must be between 1 and 50."
  }
}

variable "instance_type" {
  description = "EC2 instance type for each server."
  type        = string
  default     = "t3.small"
}

variable "root_volume_size" {
  description = "Root EBS volume size, in GB, for each instance."
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Root EBS volume type for each instance."
  type        = string
  default     = "gp3"
}

### Networking ###

variable "vpc_id" {
  description = "ID of an existing VPC to deploy into (e.g. \"vpc-0123456789abcdef0\"). Leave empty to use the account's default VPC. Must already have internet connectivity (Internet Gateway + route table) if you want SSH access."
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "ID of an existing subnet to deploy all instances into (e.g. \"subnet-0123456789abcdef0\"). Leave empty to round-robin instances across all subnets of the resolved VPC (default VPC's subnets if vpc_id is also empty)."
  type        = string
  default     = ""
}

### SSH access ###

variable "ssh_public_key_path" {
  description = "Local path to the SSH public key file to import into AWS for instance access (e.g. \"../keys/github-workshop.pub\"). Must be supplied explicitly."
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH (port 22) into the instances. Defaults to open access for lab convenience; tighten for anything beyond a throwaway lab."
  type        = string
  default     = "0.0.0.0/0"
}

variable "allowed_web_cidr" {
  description = "CIDR block allowed to open the nginx page (port 8080) on the instances. Defaults to open access so participants can reach their page from anywhere."
  type        = string
  default     = "0.0.0.0/0"
}

### RHEL AMI selection ###

variable "rhel_ami_owner" {
  description = "AWS account ID that owns the RHEL AMIs to look up (Red Hat's official account by default)."
  type        = string
  default     = "309956199498"
}

variable "rhel_ami_name_filter" {
  description = "Name filter pattern used to select the RHEL AMI (e.g. \"RHEL-9*\" or \"RHEL-8*\")."
  type        = string
  default     = "RHEL-9*"
}

### Naming / tagging ###

variable "name_prefix" {
  description = "Prefix used for naming the key pair, security group, and instances."
  type        = string
  default     = "aap-workshop"
}

variable "tags" {
  description = "Additional common tags to apply to all resources."
  type        = map(string)
  default     = {}
}
