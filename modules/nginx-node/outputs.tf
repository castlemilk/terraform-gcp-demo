output "public_address" {
  value       = "${google_compute_instance.nginx-node.network_interface[0].access_config[0].nat_ip}"
  description = "Public address the deployed instance is available on"
  sensitive   = false
}