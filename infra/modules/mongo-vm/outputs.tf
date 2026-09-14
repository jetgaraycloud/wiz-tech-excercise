output "public_ip" {
  value = aws_instance.mongo_vm.public_ip
}

output "backup_bucket_name" {
  value = aws_s3_bucket.mongo_backups.bucket
}
