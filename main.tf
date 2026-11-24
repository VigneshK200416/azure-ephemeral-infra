terraform {
  required_version = ">=1.4.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.0"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

# Binds this state to one ticket and one region on first apply. A different tfvars file, or a changed
# region, then fails the plan instead of silently destroying the existing deployment.
resource "terraform_data" "ticket_binding" {
  input = { id = var.ticket.id, location = var.ticket.location }
  lifecycle { ignore_changes = [input] }
}

resource "terraform_data" "ticket_guard" {
  lifecycle {
    precondition {
      condition     = terraform_data.ticket_binding.output.id == var.ticket.id
      error_message = "This state belongs to ticket ${terraform_data.ticket_binding.output.id}, but the file says ${var.ticket.id}. Wrong tfvars file or wrong state key."
    }
    precondition {
      condition     = terraform_data.ticket_binding.output.location == var.ticket.location
      error_message = "Region cannot change for an existing ticket (${terraform_data.ticket_binding.output.location} to ${var.ticket.location}). Destroy it first or restore the original region."
    }
  }
}

# One ticket file = one ticket = one state, so RG and network are called once.
module "RG" {
  source     = "./modules/Ticket-module"
  depends_on = [terraform_data.ticket_guard]
  ticket_id  = var.ticket.id
  location   = var.ticket.location
  poc        = var.ticket.poc
}

module "nw" {
  source = "./modules/NW-NSG"

  ticket-id           = module.RG.ticket_id
  resource_group_name = module.RG.Resource_group
  location            = module.RG.Resource_group_location
  access              = var.ticket.access
  office_ips          = var.office_ips
}

# Only the VMs loop. The map key is the VM name (web, db, ...).
module "vm" {
  source   = "./modules/VM"
  for_each = var.vms

  ticket-id      = module.RG.ticket_id
  vm_name        = each.key
  resource_group = module.RG.Resource_group
  location       = module.RG.Resource_group_location
  subnet         = module.nw.subnet
  nsg_name       = module.nw.nsg_name
  office_ips     = var.office_ips

  OS_type       = each.value.OS_type
  vm_size       = each.value.vm_size
  disk_sku      = each.value.disk_sku
  disk_size_gb  = each.value.disk_size_gb
  rule_priority = each.value.rule_priority

  public_key     = var.public_key
  admin_password = var.admin_password
}
