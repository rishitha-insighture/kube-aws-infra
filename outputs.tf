# Optional: Map of instance names to private IPs
output "knode_ips_map" {
  description = "Map of instance names to their private IPs"
  value = {
    for idx, instance in aws_instance.knode :
    "knode${idx + 1}" => instance.private_ip
  }
}
