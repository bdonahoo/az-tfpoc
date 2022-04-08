# address space for the vnet
variable "vnet_address_space" {
  default = ["10.0.0.0/16"]
}
# address spaces for the 4 subnets
variable "subnet_address_space" {
  default = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}
