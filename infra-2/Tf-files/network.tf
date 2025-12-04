# virtual network
resource "azurerm_virtual_network" "dia-vnet" {
  name                = "${var.service_name}-${var.environment}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Subnet 
resource "azurerm_subnet" "dia-frontend-subnet" {
  name                 = "${var.service_name}-${var.environment}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.dia-vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints = [
    "Microsoft.Web"
  ]
  delegation {
    name = "Microsoft.Web.serverFarms"
    service_delegation {
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action"
      ]
      name = "Microsoft.Web/serverFarms"
    }
  }
}

# app getway subnet
resource "azurerm_subnet" "dia-app-gateway-subnet" {
  name                 = "${var.service_name}-${var.environment}-app-gateway-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.dia-vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

#puplic ip for app gateway
resource "azurerm_public_ip" "dia-app-gateway-public-ip" {
  name                = "${var.service_name}-${var.environment}-app-gateway-public-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# network security group
resource "azurerm_network_security_group" "nsg" {
  name                = "dia-app-gateway-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# network security rule
resource "azurerm_network_security_rule" "rule" {
  name                        = "AllowMyIP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*" #"65200-65535"  # 
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# nsg_rules = {
#   "0" = {
#     name                         = "ALLOW_GATEWAY_MANAGER"
#     description                  = "Required allow Gateway Manager rule"
#     protocol                     = "Tcp"
#     access                       = "Allow"
#     priority                     = 100
#     direction                    = "Inbound"
#     source_port_range            = "*"
#     destination_port_ranges      = ["65200-65535"]
#     source_address_prefix        = "GatewayManager"
#     source_address_prefixes      = []
#     destination_address_prefix   = "*"
#     destination_address_prefixes = []
#   },
#   "1" = {
#     name                         = "d_lab_VPN"
#     description                  = "d_lab Digital VPN address"
#     protocol                     = "Tcp"
#     access                       = "Allow"
#     priority                     = 110
#     direction                    = "Inbound"
#     source_port_range            = "*"
#     destination_port_ranges      = ["80", "443"]
#     source_address_prefix        = ""
#     source_address_prefixes      = ["51.124.104.155/32"]
#     destination_address_prefix   = ""
#     destination_address_prefixes = ["10.220.45.0/24"]
#   }
# }

# NSG association 
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = azurerm_subnet.dia-app-gateway-subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
