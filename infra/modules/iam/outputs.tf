output "mongo_vm_instance_profile_name" {
  value = aws_iam_instance_profile.mongo_vm.name
}

output "mongo_vm_role_arn" {
  value = aws_iam_role.mongo_vm.arn
}
