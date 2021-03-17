output "instance_id" {
  value = aws_instance.nfs_instance.id
}
output "private_ip" {
  value = aws_instance.nfs_instance.private_ip
}
output "nfs_export_path" {
  value = var.nfs_export_path
}
