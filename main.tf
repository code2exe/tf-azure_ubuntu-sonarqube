provider "azurerm" {
  version = "~>2.0"
  features {}
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

#Create Resource Group
resource "azurerm_resource_group" "rg" {
  name = "myRG"
  location = var.location
  tags = {
        environment = "Terraform Demo"
    }
}

#Create Virtual Network
resource "azurerm_virtual_network" "myvnet" {
    name                = "myVnet"
    address_space       = ["10.0.0.0/16"]
    location            = var.location
    resource_group_name = azurerm_resource_group.rg.name

    tags = {
        environment = "Terraform Demo"
    }
}
#Create Subnet
resource "azurerm_subnet" "mysubnet" {
    name                 = "mySubnet"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.myvnet.name
    address_prefixes       = ["10.0.1.0/24"]
}

#Create Public IP
resource "azurerm_public_ip" "myip" {
    name                         = "myIP"
    location                     = var.location
    resource_group_name          = azurerm_resource_group.rg.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Terraform Demo"
    }
}
#Create Network Security Groups
resource "azurerm_network_security_group" "mynsg" {
    name                = "myNSG"
    location            = var.location
    resource_group_name = azurerm_resource_group.rg.name

    security_rule {
        name                       = "allow-ssh"
        description                = "allow-ssh"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "allow-http"
        description                = "allow-http"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "Internet"
        destination_address_prefix = "*"
  }
    security_rule {
        name                       = "allow-https"
        description                = "allow-https"
        priority                   = 120
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
  }

    tags = {
        environment = "Terraform Demo"
    }
}
#Create NIC
resource "azurerm_network_interface" "mynic" {
    name                        = "myNIC"
    location                    = var.location
    resource_group_name         = azurerm_resource_group.rg.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.mysubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.myip.id
    }

    tags = {
        environment = "Terraform Demo"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
    network_interface_id      = azurerm_network_interface.mynic.id
    network_security_group_id = azurerm_network_security_group.mynsg.id
}

# Generate random names for the VM's storage account for diagnostics
resource "random_id" "randomId" {
    keepers = {
        
        resource_group = azurerm_resource_group.rg.name
    }

    byte_length = 8
}
# Provision storage account for VM diagnostics 
resource "azurerm_storage_account" "myvmstorage" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.rg.name
    location                    = var.location
    account_replication_type    = "LRS"
    account_tier                = "Standard"

    tags = {
        environment = "Terraform Demo"
    }
}

# Provision SSH Key
resource "tls_private_key" "myssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}

data "template_file" "linux-vm-cloud-init" {
  template = file("./scripts/sonar.sh")
}
# Provision Linux VM 
resource "azurerm_linux_virtual_machine" "myvm" {
    name                  = "myVM"
    location              = var.location
    resource_group_name   = azurerm_resource_group.rg.name
    network_interface_ids = [azurerm_network_interface.mynic.id]
    size                  = "Standard_B2s"
    computer_name  = "myVM"
    admin_username = var.admin_username
    custom_data = base64encode(data.template_file.linux-vm-cloud-init.rendered)
    disable_password_authentication = true
    os_disk {
        name              = "myDisk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }
    admin_ssh_key {
        username       = var.admin_username
        public_key     = tls_private_key.myssh.public_key_openssh
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.myvmstorage.primary_blob_endpoint
    }

    tags = {
        environment = "Terraform Demo"
    }
}
resource "local_file" "mykey" { 
  filename = "${path.module}/mykey.pem"
  content = tls_private_key.myssh.private_key_pem
}