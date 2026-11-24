variable "ticket-id" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "access" {
  type    = list(string)
  default = []
}

variable "office_ips" {
  type = list(string)
}
