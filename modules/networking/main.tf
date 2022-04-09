# create a resource group
resource "azurerm_resource_group" "az-tf-poc" {
  name     = var.rg_name
  location = var.region
}

# configure vnet
resource "azurerm_virtual_network" "tf-poc-vnet" {
  name                = "tf-poc-vnet"
  depends_on          = [azurerm_resource_group.az-tf-poc]
  resource_group_name = var.rg_name
  location            = var.region
  address_space       = var.vnet_address_space
}
# loop through subnets
# borrowed & modified from https://stackoverflow.com/questions/61900722/creating-subnet-in-a-loop-in-terraform
resource "azurerm_subnet" "tf-poc-vnet-subnets" {
  name                 = "Sub${count.index + 1}" #increment the count so the subnets are named correctly!
  depends_on           = [azurerm_virtual_network.tf-poc-vnet]
  count                = 4
  resource_group_name  = var.rg_name
  virtual_network_name = "tf-poc-vnet"
  address_prefixes     = ["${element(var.subnet_address_space, count.index)}"]
}
# create nics for the VMs in sub1
resource "azurerm_network_interface" "rhel-nics" {
  count               = 2
  name                = "rhel0${count.index + 1}-nic"
  depends_on          = [azurerm_subnet.tf-poc-vnet-subnets]
  location            = var.region
  resource_group_name = var.rg_name
  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.tf-poc-vnet-subnets[0].id
    private_ip_address_allocation = "Dynamic"
  }
}
# nic for the apache box in sub3
resource "azurerm_network_interface" "apache-nic" {
  name                = "apache-nic"
  depends_on          = [azurerm_subnet.tf-poc-vnet-subnets]
  location            = var.region
  resource_group_name = var.rg_name
  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.tf-poc-vnet-subnets[2].id
    private_ip_address_allocation = "Static" # don't want this to change
    private_ip_address            = var.apache-private-ip
  }
}
# nsg for sub1
resource "azurerm_network_security_group" "sub1-nsg" {
  name                = "sub1-nsg"
  depends_on          = [azurerm_subnet.tf-poc-vnet-subnets]
  location            = var.region
  resource_group_name = var.rg_name
  security_rule {
    name                       = "allow_ssh_vnet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "22" #ssh
    destination_port_range     = "*"
    source_address_prefix      = var.vnet_address_space[0] # open to vnet
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "vnet_deny_all"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.vnet_address_space[0]
    destination_address_prefix = "*"
  }
}
# nsg for sub2
resource "azurerm_network_security_group" "sub2-nsg" {
  name                = "sub2-nsg"
  depends_on          = [azurerm_subnet.tf-poc-vnet-subnets]
  location            = var.region
  resource_group_name = var.rg_name
  security_rule {
    name                       = "allow_load_balancer"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "80" # http
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "deny_all"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}
# load balancer public ip
resource "azurerm_public_ip" "frontend-pip" {
  name                = "frontend-pip"
  depends_on          = [azurerm_resource_group.az-tf-poc]
  resource_group_name = var.rg_name
  location            = var.region
  allocation_method   = "Static"
  sku                 = "Standard"
}

# load balancer
resource "azurerm_lb" "alb" {
  name                = "poc-alb"
  depends_on          = [azurerm_public_ip.frontend-pip]
  location            = var.region
  resource_group_name = var.rg_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "frontend"
    public_ip_address_id = azurerm_public_ip.frontend-pip.id
  }
}
# For the alb backend, first create a probe, then a pool, then fill the pool, then link it with a rule
resource "azurerm_lb_probe" "http-probe" {
  depends_on      = [azurerm_lb.alb]
  loadbalancer_id = azurerm_lb.alb.id
  name            = "http-probe"
  port            = 80
}
resource "azurerm_lb_backend_address_pool" "apache-backend" {
  depends_on      = [azurerm_lb.alb]
  loadbalancer_id = azurerm_lb.alb.id
  name            = "alb-backend"
}
resource "azurerm_lb_backend_address_pool_address" "apache-pool-membership" {
  depends_on              = [azurerm_lb_backend_address_pool.apache-backend]
  name                    = "apache"
  backend_address_pool_id = azurerm_lb_backend_address_pool.apache-backend.id
  virtual_network_id      = azurerm_virtual_network.tf-poc-vnet.id
  ip_address              = var.apache-private-ip
}
resource "azurerm_lb_rule" "apache-route" {
  depends_on                     = [azurerm_lb_backend_address_pool_address.apache-pool-membership]
  loadbalancer_id                = azurerm_lb.alb.id
  name                           = "apache-route"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = azurerm_lb.alb.frontend_ip_configuration[0].name
}
