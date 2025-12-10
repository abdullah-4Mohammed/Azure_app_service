# data to fetch the configuration of the Azure provider, including the tenant ID, subscription ID, and client ID.
data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  sku                 = "Standard"
  admin_enabled       = true
}

#App Service Plan for App Service  
resource "azurerm_app_service_plan" "asp" {
  name                = "${var.service_name}-${var.environment}-asp"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  #worker_count            = var.worker_count
  kind                = var.kind
  #os_type             = var.app_plan_os_type #outdated
  reserved            = true
  #sku_name            = "var.app_plan_sku_name" # outdated

  # # sku Stock Keeping Unit - the price tier and size
  # sku {
  # tier = "Free"      # Free
  # size = "F1"        # Shared, 1 GB RAM, 60 min/day limit
  # }

    # sku Stock Keeping Unit - the price tier and size
  # tier: The pricing/feature level (Free, Basic, Standard, Premium)
  # size: The instance size within that tier (F1, B1, S1, P1, etc.)

  # sku {
  #   tier = "Standard"   # Costs ~$70/month
  #   size = "S1"   # 1 core, 1.75 GB RAM
  # }

  sku {
    tier = "Basic"     # Costs ~$13/month
    size = "B1"        # 1 core, 1.75 GB RAM
  }

}

#App Service
resource "azurerm_linux_web_app" "web-app" {
  name                = "${var.service_name}-${var.environment}-app"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id = azurerm_app_service_plan.asp.id
  #https_only          = true
  #virtual_network_subnet_id = azurerm_subnet.dia-frontend-subnet.id   # free tier app svc dosnt support vnet attachming
  
  identity {
    type = "SystemAssigned"
  }
  
  site_config {
    always_on = true #false  # Change from true becuase cant be done on free tier
    #linux_fx_version = "DOCKER|${var.docker_registry_server_name}/${var.docker_custom_image_name}:${var.docker_custom_image_tag}"
    #   ip_restriction {
    #   action      = "Allow"
    #   headers     = []
    #   ip_address  = "86.5.141.187/32" #my IP
    #   name        = "Allow MM VPN"
    #   priority    = 100
    # }
    # ip_restriction {
    #   action      = "Deny"
    #   headers     = []
    #   ip_address   = "0.0.0.0/0"
    #   name        = "Deny all"
    #   priority    = 50000
    # }
    #vnet_route_all_enabled = true  #free tier app svc dosnt support net attach
  
  }
    
  app_settings = {

  APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.dia-app-insights.instrumentation_key,
  APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.dia-app-insights.connection_string,
  DOCKER_REGISTRY_SERVER_URL = "diadevacr.azurecr.io",
  DOCKER_REGISTRY_SERVER_USERNAME = "diadevacr",
  DOCKER_REGISTRY_SERVER_PASSWORD = azurerm_container_registry.acr.admin_password,
  #DOCKER_REGISTRY_SERVER_PASSWORD = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.kv_secret_acr_password.versionless_id})" ,
  DOCKER_CUSTOM_IMAGE_NAME =  "diadevacr.azurecr.io/web-app:latest",
  
}

  # site_config {
  #   ip_restriction {
  #     action      = "Allow"
  #     headers     = []
  #     ip_address  = "86.5.141.187/32" #my IP
  #     name        = "Allow MM VPN"
  #     priority    = 100
  #   }
  #   ip_restriction {
  #     action      = "Deny"
  #     headers     = []
  #     ip_address   = "0.0.0.0/0"
  #     name        = "Deny all"
  #     priority    = 50000
  # }
  #   vnet_route_all_enabled = true
  # }

 }

  # add azurerm_log_analytics_workspace
  resource "azurerm_log_analytics_workspace" "dia-la" {
  name                = "${var.service_name}-${var.environment}-la"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  
}

resource "azurerm_application_insights" "dia-app-insights" {
  name                = "${var.service_name}-${var.environment}-ai"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.dia-la.id

}

#add azure app gateway
resource "azurerm_application_gateway" "dia-app-gateway" {
  name                = "${var.service_name}-${var.environment}-app-gateway"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101"
  }
  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }
  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = azurerm_subnet.dia-app-gateway-subnet.id
  }
  frontend_port {
    name = "appGatewayFrontendPort"
    port = 80
  }
  frontend_ip_configuration {
    name                 = "appGatewayFrontendIP"
    public_ip_address_id = azurerm_public_ip.dia-app-gateway-public-ip.id
  }
  #The target servers the Application Gateway forwards traffic to.
  backend_address_pool {
    name = "appGatewayBackendPool"
    #fqdns = ["dlab-dia-uks-dev-app.azurewebsites.net"]
    fqdns = ["${azurerm_linux_web_app.web-app.default_hostname}"]
  }
  #How the Application Gateway communicates with the backend.
  backend_http_settings {
    name                  = "appGatewayBackendHttpSettings"
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
    #Override with new host name
    #host_name = "dlab-dia-uks-dev-app.azurewebsites.net"
    host_name = azurerm_linux_web_app.web-app.default_hostname
  }
  http_listener {
    name                           = "appGatewayHttpListener"
    frontend_ip_configuration_name = "appGatewayFrontendIP"
    frontend_port_name             = "appGatewayFrontendPort"
    protocol                       = "Http"
  }
  request_routing_rule {
    name                       = "appGatewayRule"
    rule_type                  = "Basic"
    http_listener_name         = "appGatewayHttpListener"
    backend_address_pool_name  = "appGatewayBackendPool"
    backend_http_settings_name = "appGatewayBackendHttpSettings"
    priority = 100
  } 
  # ssl_certificate {
  #   name     = "appGatewaySslCert"
  #   data     = filebase64(var.ssl_certificate_path)
  #   password = var.ssl_certificate_password
  # }
  # frontend_port {
  #   name = "appGatewayFrontendPortHttps"
  #   port = 443
  # }
  # frontend_ip_configuration {
  #   name                 = "appGatewayFrontendIPHttps"
  #   public_ip_address_id = azurerm_public_ip.dia-app-gateway-public-ip.id
  #   #https settings
  #   ssl_certificate_name = "appGatewaySslCert"
  # }
  # http_listener {
  #   name                           = "appGatewayHttpListenerHttps"
  #   frontend_ip_configuration_name = "appGatewayFrontendIPHttps"
  #   frontend_port_name             = "appGatewayFrontendPortHttps"
  #   protocol                       = "Https"
  #   ssl_certificate_name           = "appGatewaySslCert"
  # }

}
