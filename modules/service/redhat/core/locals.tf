locals {
  // 面の識別子
  section_id = terraform.workspace

  app_cluster_quorum_size = floor(length(var.app_cluster_hosts) / 2) + 1

  sudo_askpass_path = "~/.sudo/askpass.sh"
}
