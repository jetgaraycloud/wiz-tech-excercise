# Intentionally outdated AMI (Ubuntu 20.04 Focal — 1+ year old release line)
data "aws_ami" "outdated_ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "mongo_vm" {
  name        = "${var.project_name}-mongo-vm-sg"
  description = "SSH open to the internet, Mongo restricted to K8s subnets (intentional per exercise)"
  vpc_id      = var.vpc_id

  # Intentional misconfig: SSH must be exposed to the public internet
  ingress {
    description = "SSH from anywhere (intentional misconfig per exercise spec)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  # MongoDB restricted to K8s private subnets only, per exercise requirement
  ingress {
    description = "MongoDB from K8s subnets only"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = var.k8s_subnet_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-mongo-vm-sg"
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "mongo_backups" {
  bucket = "${var.project_name}-mongo-backups-${random_id.suffix.hex}"

  tags = {
    Name = "${var.project_name}-mongo-backups"
  }
}

# Intentional misconfig: object storage must allow public read and public listing
resource "aws_s3_bucket_public_access_block" "mongo_backups" {
  bucket = aws_s3_bucket.mongo_backups.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "mongo_backups_public" {
  bucket = aws_s3_bucket.mongo_backups.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadAndList"
      Effect    = "Allow"
      Principal = "*"
      Action    = ["s3:GetObject", "s3:ListBucket"]
      Resource = [
        aws_s3_bucket.mongo_backups.arn,
        "${aws_s3_bucket.mongo_backups.arn}/*"
      ]
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.mongo_backups]
}

resource "aws_instance" "mongo_vm" {
  ami                    = data.aws_ami.outdated_ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.mongo_vm.id]
  iam_instance_profile   = var.instance_profile_name

  user_data = templatefile("${path.module}/scripts/user_data.sh.tpl", {
    backup_bucket = aws_s3_bucket.mongo_backups.bucket
  })

  tags = {
    Name = "${var.project_name}-mongo-vm"
  }
}
