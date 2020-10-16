output "azurerm_public_ip" { 
    value = azurerm_linux_virtual_machine.myvm.public_ip_address
    }