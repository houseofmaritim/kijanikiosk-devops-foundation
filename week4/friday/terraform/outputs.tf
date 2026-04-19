output "server_public_ips" {
  description = "Public IPs of all provisioned servers"
  value = {
    for name, mod in module.app_servers :
    name => mod.public_ip
  }
}

output "ansible_inventory" {
  description = "Ready-to-use Ansible inventory lines"
  value = join("\n", [
    for name, mod in module.app_servers :
    "${name} ansible_host=${mod.public_ip} ansible_user=ubuntu"
  ])
}
