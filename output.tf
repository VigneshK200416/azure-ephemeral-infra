output "resource_group" {
  value = module.RG.Resource_group
}

output "vm-ip" {
  value = { for k, v in module.vm : k => v.public_ip }
}
