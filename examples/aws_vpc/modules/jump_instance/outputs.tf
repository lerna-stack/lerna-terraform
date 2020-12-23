output "iam_profile_name" {
  value = aws_iam_instance_profile.jump_instance_profile.name
}
output "id" {
  value = aws_instance.jump_instance.id
}
output "key_name" {
  value = aws_key_pair.jump_instance_key_pair.key_name
}
