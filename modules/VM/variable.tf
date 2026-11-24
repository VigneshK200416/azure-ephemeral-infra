variable "ticket-id" {
  type = string
}

variable "vm_name" {
  type        = string
  description = "VM role (web, db). Goes into every resource name and is the Windows computer name."
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,13}[a-z0-9]$", var.vm_name))
    error_message = "vm_name must be 2 to 15 characters: lowercase letters, digits and hyphens, starting with a letter and not ending with a hyphen."
  }
}

variable "location" {
  type    = string
  default = "centralindia"
}

variable "resource_group" {
  type = string
}

variable "subnet" {
  type = string
}

variable "nsg_name" {
  type = string
}

variable "office_ips" {
  type = list(string)
}

variable "rule_priority" {
  type = number
  validation {
    condition     = var.rule_priority >= 1000 && var.rule_priority <= 1999
    error_message = "rule_priority must be between 1000 and 1999."
  }
}

variable "OS_type" {
  type = string
  validation {
    condition     = contains(["ubuntu", "ubuntu22", "ubuntu24", "win", "win10", "win11", "winserver", "win2025"], lower(var.OS_type))
    error_message = "currently supported windows and ubuntu only"
  }
}

variable "vm_size" {
  type    = string
  default = "Standard_D2as_v5"
  validation {
    condition     = contains(["Standard_B2as_v2", "Standard_B4as_v2", "Standard_D4as_v5", "Standard_D2as_v5"], var.vm_size)
    error_message = "provide a valid vm_size"
  }
}

variable "disk_sku" {
  type    = string
  default = "StandardSSD_LRS"
  validation {
    condition     = contains(["Standard_LRS", "StandardSSD_LRS", "Premium_LRS"], var.disk_sku)
    error_message = "disk_sku must be Standard_LRS, StandardSSD_LRS or Premium_LRS"
  }
}

# null = use the image size. Which tiers are allowed per OS is checked in main.tf.
variable "disk_size_gb" {
  type    = number
  default = null
  validation {
    condition     = var.disk_size_gb == null ? true : contains([32, 64, 128, 256, 512], var.disk_size_gb)
    error_message = "disk_size_gb must be one of 32, 64, 128, 256, 512 (or omitted)."
  }
}

variable "user" {
  type    = string
  default = "syncfusion"
}

variable "public_key" {
  type      = string
  default   = null
  sensitive = true
}

variable "admin_password" {
  type      = string
  default   = null
  sensitive = true
}
