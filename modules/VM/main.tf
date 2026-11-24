locals {
  is_linux      = startswith(lower(var.OS_type), "ubuntu")
  ubuntu_offer  = lower(var.OS_type) == "ubuntu22" ? "0001-com-ubuntu-server-jammy" : "ubuntu-24_04-lts"
  ubuntu_sku    = lower(var.OS_type) == "ubuntu22" ? "22_04-lts-gen2" : "server"
  win_publisher = lower(var.OS_type) == "win2025" || lower(var.OS_type) == "winserver" ? "MicrosoftWindowsServer" : "MicrosoftWindowsDesktop"
  win_offer     = local.win_publisher == "MicrosoftWindowsServer" ? "WindowsServer" : lower(var.OS_type) == "win10" ? "Windows-10" : "Windows-11"
  win_sku = (
    local.win_publisher == "MicrosoftWindowsServer" ? "2025-datacenter-azure-edition" :
    lower(var.OS_type) == "win10" ? "win10-22h2-pro-g2" : "win11-26h2-pro"
  )

  # Naming: <type>-<ticket>-<vm role>, built once here. The tfvars key is the role only (web, db), never the ticket number.
  suffix = "${var.ticket-id}-${var.vm_name}"

  # Billing tiers. Linux images are about 30 GB, Windows images about 127 GB.
  linux_disk_sizes   = [32, 64, 128]
  windows_disk_sizes = [128, 256, 512]
}

resource "azurerm_windows_virtual_machine" "Temp" {
  count                 = local.is_linux ? 0 : 1
  name                  = "vm-${local.suffix}"
  computer_name         = var.vm_name # role only; the 15-character Windows limit is enforced on vm_name
  size                  = var.vm_size
  resource_group_name   = var.resource_group
  location              = var.location
  network_interface_ids = [azurerm_network_interface.Temp.id]
  admin_username        = var.user
  admin_password        = var.admin_password
  source_image_reference {
    publisher = local.win_publisher
    sku       = local.win_sku
    offer     = local.win_offer
    version   = "latest"
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.disk_sku
    disk_size_gb         = var.disk_size_gb
  }

  lifecycle {
    precondition {
      condition     = var.admin_password != null
      error_message = "Windows VM needs a password. In the terminal: $env:TF_VAR_admin_password = \"<password>\""
    }
    precondition {
      condition     = var.disk_size_gb == null ? true : contains(local.windows_disk_sizes, var.disk_size_gb)
      error_message = "Windows disk_size_gb must be 128, 256 or 512 (or omitted)."
    }
  }
}

resource "azurerm_linux_virtual_machine" "Temp" {
  count                 = local.is_linux ? 1 : 0
  name                  = "vm-${local.suffix}"
  size                  = var.vm_size
  resource_group_name   = var.resource_group
  location              = var.location
  network_interface_ids = [azurerm_network_interface.Temp.id]
  admin_username        = var.user
  admin_ssh_key {
    username   = var.user
    public_key = var.public_key
  }
  source_image_reference {
    publisher = "Canonical"
    sku       = local.ubuntu_sku
    offer     = local.ubuntu_offer
    version   = "latest"
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.disk_sku
    disk_size_gb         = var.disk_size_gb
  }

  lifecycle {
    precondition {
      condition     = var.public_key != null
      error_message = "Linux VM needs public_key in the tfvars file."
    }
    precondition {
      condition     = var.disk_size_gb == null ? true : contains(local.linux_disk_sizes, var.disk_size_gb)
      error_message = "Ubuntu disk_size_gb must be 32, 64 or 128 (or omitted)."
    }
  }
}

resource "azurerm_public_ip" "Temp" {
  resource_group_name = var.resource_group
  allocation_method   = "Static"
  location            = var.location
  name                = "pip-${local.suffix}"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "Temp" {
  name                = "nic-${local.suffix}"
  resource_group_name = var.resource_group
  location            = var.location
  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.Temp.id
  }
}

# Management rule: only the VM module knows the OS, so it owns the 22 / 3389 rule.
# The priority comes from the ticket file, so VMs sharing one NSG never collide.
resource "azurerm_network_security_rule" "mgmt" {
  name                        = "allow-mgmt-${local.suffix}"
  priority                    = var.rule_priority
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = local.is_linux ? "22" : "3389"
  source_address_prefixes     = var.office_ips
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group
  network_security_group_name = var.nsg_name
}
