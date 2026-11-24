
resource "azurerm_virtual_network" "Temp" {
  name                = "vnet-${var.ticket-id}"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = ["10.0.0.0/16"]

}
resource "azurerm_subnet" "Temp" {
  name                 = "snet-${var.ticket-id}"
  virtual_network_name = azurerm_virtual_network.Temp.name
  resource_group_name  = var.resource_group_name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet_network_security_group_association" "Temp" {
  subnet_id                 = azurerm_subnet.Temp.id
  network_security_group_id = azurerm_network_security_group.Temp.id
}


locals {
  # Catalog lives in the module, never in tfvars, so tickets can only pick names.
  catalog = {
    http     = { ports = ["80"], public = false, priority = 2000 }
    https    = { ports = ["443"], public = true, priority = 2010 }
    oracle   = { ports = ["1521", "2485"], public = false, priority = 2020 }
    postgres = { ports = ["5432"], public = false, priority = 2030 }
  }

  # Keep only the services this ticket asked for.
  selected = { for k, v in local.catalog : k => v if contains(var.access, k) }
}

# Bare NSG: no inline security_rule blocks, so separate rule resources never fight it.
resource "azurerm_network_security_group" "Temp" {
  name                = "nsg-${var.ticket-id}"
  location            = var.location
  resource_group_name = var.resource_group_name

  # A typo in tfvars fails at plan instead of being silently ignored.
  lifecycle {
    precondition {
      condition     = alltrue([for a in var.access : contains(keys(local.catalog), a)])
      error_message = "Unknown service in access. Allowed: ${join(", ", keys(local.catalog))}"
    }
  }
}

resource "azurerm_network_security_rule" "Temp" {
  for_each = local.selected

  name                       = "allow-${each.key}"
  priority                   = each.value.priority
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_ranges    = each.value.ports
  destination_address_prefix = "*"

  # Azure rejects both source fields together, so set the unused one to null.
  source_address_prefix   = each.value.public ? "*" : null
  source_address_prefixes = each.value.public ? null : var.office_ips

  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.Temp.name
}
