
module "nginx-node" {
  source = "./modules/nginx-node"
}

output "public_address" {
  value = "${module.nginx-node.public_address}"
}
