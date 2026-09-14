# Intentionally over-permissive role for the Mongo VM, per exercise requirement:
# "VM should be granted overly permissive CSP permissions (e.g. able to create VMs)"
resource "aws_iam_role" "mongo_vm" {
  name = "${var.project_name}-mongo-vm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# NOTE: deliberately broad (full EC2 access) to satisfy the exercise's
# intentional-misconfiguration requirement. This is a lab-only pattern,
# call this out explicitly in the presentation, do not present it as best practice.
resource "aws_iam_role_policy" "mongo_vm_overpermissive" {
  name = "${var.project_name}-mongo-vm-ec2-full"
  role = aws_iam_role.mongo_vm.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "ec2:*"
      Resource = "*"
    }]
  })
}

# Scoped-down policy the VM actually needs, for the backup script to reach S3.
# Kept separate from the intentional misconfig above so the two are easy to
# tell apart when you're explaining the environment to the panel.
resource "aws_iam_role_policy" "mongo_vm_s3_backup" {
  name = "${var.project_name}-mongo-vm-s3-backup"
  role = aws_iam_role.mongo_vm.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:PutObject", "s3:ListBucket"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_instance_profile" "mongo_vm" {
  name = "${var.project_name}-mongo-vm-profile"
  role = aws_iam_role.mongo_vm.name
}
