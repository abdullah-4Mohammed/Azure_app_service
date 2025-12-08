# create a key vault
resource "azurerm_key_vault" "dia-kv" {
  name                        = "${var.service_name}-${var.environment}-kv"
  resource_group_name         = var.resource_group_name
  location                    = var.location
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  depends_on = [
    azurerm_resource_group.rg
  ]
}

# Give pipeline permissions required for TF to run
resource "azurerm_key_vault_access_policy" "dia-kv_policy_pipeline" {
  key_vault_id = azurerm_key_vault.dia-kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id
  key_permissions = [
    "Create",
    "Get",
    "List"
  ]
  secret_permissions = [
    "Set",
    "Get",
    "Delete",
    "Purge",
    "Recover",
    "List"
  ]
  depends_on = [ azurerm_key_vault.dia-kv ]
}

# Permissions for normal Users
resource "azurerm_key_vault_access_policy" "dia-kv_policy_users" {
  key_vault_id = azurerm_key_vault.dia-kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = "e5578fee-a5d4-4279-adf9-6b8d8a97656e" # it should be the object ID of Me Abdullah
  key_permissions = [
    "Create",
    "Get",
    "List"
  ]
  secret_permissions = [
    "Set",
    "Get",
    "Delete",
    "Purge",
    "Recover",
    "List"
  ]
  depends_on = [ azurerm_key_vault.dia-kv ]
}

# Permissions for the App Service
resource "azurerm_key_vault_access_policy" "kv_policy" {
  key_vault_id = azurerm_key_vault.dia-kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_web_app.web-app.identity[0].principal_id
  secret_permissions = [
    "Get"
  ]
  depends_on = [ azurerm_key_vault.dia-kv ]
}

# Add secrets in here
resource "azurerm_key_vault_secret" "kv_secret_acr_password" {
  name         = "acr-password"
  value        = azurerm_container_registry.acr.admin_password #"" # leave it embty "" to be filled manually or replace it with dynamic expression to get acr pw dynamiclly.
  key_vault_id = azurerm_key_vault.dia-kv.id

  # if we used managed identity , the acr will use the app svc to give it permission to acess it for pull and push. then 
  # we will not need to kv and secret to give app svc permission for acr. kv will needed just if we have more screts for other services.
  
  # prevents Terraform from overwriting. it needed if the pw to be filled manually and to insure tf not override that.
  # lifecycle {
  #   ignore_changes = [value] # prevents Terraform from overwriting. it needed if the pw to be filled manually and to insure tf not override that.
  # }
  depends_on = [ 
    azurerm_key_vault.dia-kv,
    azurerm_key_vault_access_policy.dia-kv_policy_pipeline,
    azurerm_key_vault_access_policy.dia-kv_policy_users
    ]
}
