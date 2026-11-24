resource "azurerm_resource_group" "Temp" {
  name     = "Ticket-${var.ticket_id}"
  location = var.location
  tags = {
    "ticket_id"  = var.ticket_id
    "Owner"      = var.poc
    "created_on" = timestamp()
  }

  lifecycle {
    ignore_changes = [
      tags["created_on"]
    ]
  }

}

