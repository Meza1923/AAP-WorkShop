### Data sources ###

data "aws_caller_identity" "current" {}

data "aws_vpc" "default" {
  count   = var.vpc_id == "" ? 1 : 0
  default = true
}

locals {
  vpc_id = var.vpc_id != "" ? var.vpc_id : data.aws_vpc.default[0].id
}

data "aws_subnets" "default" {
  count = var.subnet_id == "" ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }
}

locals {
  subnet_ids = var.subnet_id != "" ? [var.subnet_id] : data.aws_subnets.default[0].ids
}

data "aws_ami" "rhel" {
  most_recent = true
  owners      = [var.rhel_ami_owner]

  filter {
    name   = "name"
    values = [var.rhel_ami_name_filter]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

### Guard against deploying into the wrong AWS account ###

check "account_id_matches" {
  assert {
    condition     = var.aws_account_id == "" || var.aws_account_id == data.aws_caller_identity.current.account_id
    error_message = "var.aws_account_id does not match the account associated with the supplied credentials — you may be targeting the wrong AWS account."
  }
}

### SSH key pair ###

resource "aws_key_pair" "workshop" {
  key_name   = "${var.name_prefix}-key"
  public_key = file(var.ssh_public_key_path)
}

### Security group ###

resource "aws_security_group" "ssh" {
  name        = "${var.name_prefix}-ssh-sg"
  description = "Allow SSH access to workshop RHEL instances"
  vpc_id      = local.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # Activity 1 Part A: participants open http://<vm-address>:8080
  ingress {
    description = "nginx web page"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.allowed_web_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ssh-sg"
  })
}

### EC2 instances ###

resource "aws_instance" "rhel" {
  count = var.instance_count

  ami                    = data.aws_ami.rhel.id
  instance_type          = var.instance_type
  subnet_id              = element(local.subnet_ids, count.index % length(local.subnet_ids))
  vpc_security_group_ids = [aws_security_group.ssh.id]
  key_name               = aws_key_pair.workshop.key_name

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    delete_on_termination = true
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-${count.index + 1}"
  })
}
