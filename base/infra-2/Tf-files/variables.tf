variable "resource_group_name" {
  type        = string
  description = "RG name in Azure"
}

variable "location" {
  type        = string
  description = "Resources location in Azure"
}

variable "acr_name" {
  type        = string
  description = "ACR name"
}

variable "fileshare_name" {
  type        = string
  description = "Fileshare name"
  
}

variable "service_name" {
  type        = string
  description = "App Service name"
  
}

variable "kind" {
  type        = string
  description = "App Service Plan OS type"
  
}

variable "environment" {
  type = string
  description = "Environment name"
}
