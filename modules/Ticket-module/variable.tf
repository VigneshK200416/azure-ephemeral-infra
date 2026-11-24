variable "ticket_id" {
  type        = string
  description = "Ticket ID for the resource group"
}
variable "location" {
  default     = "centralindia"
  type        = string
  description = "Location for the resource group"
}
variable "poc" {
  type        = string
  description = "Point of contact for the resource group"
}