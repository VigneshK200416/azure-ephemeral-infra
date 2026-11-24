variable "subscription_id" {
  type = string
}

variable "ticket" {
  type = object({
    id       = string
    location = optional(string, "centralindia")
    poc      = string
    access   = optional(list(string), [])
  })

  validation {
    condition     = can(regex("^[0-9]+$", var.ticket.id))
    error_message = "ticket.id must be digits only."
  }

  # Edit this list to the regions you are allowed to use. Lowercase, exactly as written here.
  validation {
    condition     = contains(["centralindia", "southindia", "westindia", "southeastasia"], var.ticket.location)
    error_message = "ticket.location must be one of: centralindia, southindia, westindia, southeastasia (lowercase)."
  }
}

# Map key = VM name. Empty map is allowed (a base-only ticket).
variable "vms" {
  type = map(object({
    OS_type       = string
    vm_size       = optional(string, "Standard_D2as_v5")
    disk_sku      = optional(string, "StandardSSD_LRS")
    disk_size_gb  = optional(number) # null = use the image size
    rule_priority = number
  }))
  default = {}

  validation {
    condition     = alltrue([for k in keys(var.vms) : can(regex("^[a-z][a-z0-9-]{0,13}[a-z0-9]$", k))])
    error_message = "VM names (map keys) must be 2 to 15 characters: lowercase letters, digits and hyphens, starting with a letter and not ending with a hyphen. Use the role (web, db), not the ticket number."
  }

  validation {
    condition     = length(distinct([for v in values(var.vms) : v.rule_priority])) == length(var.vms)
    error_message = "rule_priority must be different for every VM."
  }

  validation {
    condition     = alltrue([for v in values(var.vms) : v.rule_priority >= 1000 && v.rule_priority <= 1999])
    error_message = "rule_priority must be between 1000 and 1999 (service rules use 2000 and up)."
  }
}

variable "public_key" {
  type      = string
  sensitive = true
  default   = null
}

variable "admin_password" {
  type      = string
  sensitive = true
  default   = null
}

# One list for every ticket. Defined once here, passed down to nw and vm.
variable "office_ips" {
  type    = list(string)
  default = ["203.0.113.10/32"] # REPLACE with your real office IPs (dummy documentation address)

  validation {
    condition     = length(var.office_ips) > 0
    error_message = "office_ips must not be empty."
  }
}
