# Guía de Desarrollo de Módulos para el Orquestador Azure

Esta guía explica en detalle cómo desarrollar módulos adicionales que sean compatibles con el orquestador Azure. El diseño sigue un patrón específico que permite una integración fluida y una experiencia consistente.

## Principios de Diseño

### 1. Estructura de Entrada
Los módulos deben recibir su configuración a través de un objeto estructurado que siga este patrón:

```hcl
variable "configuration" {
  description = "Objeto de configuración principal del módulo"
  type = object({
    resource_type = map(object({
      # Propiedades específicas del recurso
    }))
  })
}
```

### 2. Referencias entre Recursos
Los módulos deben recibir mapas de IDs para referenciar recursos externos:

```hcl
variable "resource_group_ids" {
  description = "Mapa de resource_group_key a ID"
  type = map(string)
}

variable "subnet_ids" {
  description = "Mapa de subnet_key a ID"
  type = map(string)
}
```

## Estructura del Módulo

```plaintext
modules/
└── your_module/
    ├── main.tf       # Recursos principales
    ├── variables.tf  # Definición de variables
    ├── outputs.tf    # Outputs estandarizados
    └── README.md     # Documentación específica
```

## Ejemplo Práctico: Módulo de Storage Account

Veamos un ejemplo completo de cómo implementar un módulo de Storage Account:

### 1. variables.tf
```hcl
variable "configuration" {
  description = "Configuración de Storage Accounts"
  type = object({
    storage_accounts = map(object({
      name                = string
      resource_group_key = string
      tier               = string
      replication_type   = string
      network_rules = optional(object({
        default_action    = string
        ip_rules         = list(string)
        subnet_keys      = list(string)
      }))
    }))
  })
}

variable "resource_group_ids" {
  description = "Mapa de resource_group_key a ID"
  type = map(string)
}

variable "subnet_ids" {
  description = "Mapa de subnet_key a ID"
  type = map(string)
}
```

### 2. main.tf
```hcl
# Data source para Resource Groups
data "azurerm_resource_group" "rg" {
  for_each = toset([
    for sa in var.configuration.storage_accounts : sa.resource_group_key
  ])
  name = var.resource_group_ids[each.value]
}

# Network Rules
locals {
  network_rules = {
    for k, v in var.configuration.storage_accounts : k => {
      default_action = try(v.network_rules.default_action, "Allow")
      ip_rules      = try(v.network_rules.ip_rules, [])
      subnet_ids    = try([
        for subnet_key in v.network_rules.subnet_keys : var.subnet_ids[subnet_key]
      ], [])
    } if v.network_rules != null
  }
}

# Storage Accounts
resource "azurerm_storage_account" "these" {
  for_each = var.configuration.storage_accounts

  name                = each.value.name
  resource_group_name = data.azurerm_resource_group.rg[each.value.resource_group_key].name
  location            = data.azurerm_resource_group.rg[each.value.resource_group_key].location
  
  account_tier             = each.value.tier
  account_replication_type = each.value.replication_type

  dynamic "network_rules" {
    for_each = contains(keys(local.network_rules), each.key) ? [local.network_rules[each.key]] : []
    content {
      default_action             = network_rules.value.default_action
      ip_rules                   = network_rules.value.ip_rules
      virtual_network_subnet_ids = network_rules.value.subnet_ids
    }
  }
}
```

### 3. outputs.tf
```hcl
output "storage_account_ids" {
  description = "Mapa de storage_account_key a ID"
  value = {
    for k, v in azurerm_storage_account.these : k => v.id
  }
}

output "storage_account_primary_access_keys" {
  description = "Mapa de storage_account_key a primary access key"
  sensitive = true
  value = {
    for k, v in azurerm_storage_account.these : k => v.primary_access_key
  }
}
```

## Integración con el Orquestador

### 1. Actualizar variables.tf del Orquestador
```hcl
variable "configuration" {
  type = object({
    # ... existing configuration ...
    storage = optional(object({
      storage_accounts = map(object({
        name                = string
        resource_group_key = string
        tier               = string
        replication_type   = string
        network_rules = optional(object({
          default_action    = string
          ip_rules         = list(string)
          subnet_keys      = list(string)
        }))
      }))
    }))
  })
}
```

### 2. Actualizar main.tf del Orquestador
```hcl
module "storage" {
  source = "./modules/storage"
  count  = var.configuration.storage != null ? 1 : 0

  configuration = var.configuration.storage
  
  resource_group_ids = {
    for k, v in azurerm_resource_group.rg : k => v.name
  }
  
  subnet_ids = {
    for k, v in azurerm_subnet.subnet : k => v.id
  }
}
```

## Mejores Prácticas

1. **Manejo de Dependencias**
   - Usar `resource_group_key` en lugar de nombres directos
   - Implementar data sources para recursos externos
   - Usar `depends_on` solo cuando sea absolutamente necesario

2. **Validación de Entrada**
```hcl
variable "configuration" {
  # ... type definition ...

  validation {
    condition = alltrue([
      for k, v in var.configuration.storage_accounts :
      can(regex("^[a-z0-9]{3,24}$", v.name))
    ])
    error_message = "Storage account names must be 3-24 characters long and contain only lowercase letters and numbers."
  }
}
```

3. **Manejo de Opcionales**
   - Usar `optional()` para campos no requeridos
   - Proporcionar valores por defecto sensatos
   - Usar `try()` para manejar campos nulos

4. **Outputs Estandarizados**
   - Siempre devolver IDs de recursos creados
   - Usar nombres consistentes (ej: `resource_ids`)
   - Marcar como `sensitive = true` datos sensibles

5. **Documentación**
   - README.md con ejemplos de uso
   - Documentar cada variable y output
   - Incluir validaciones y restricciones

## Ejemplo de Uso en JSON

```json
{
  "configuration": {
    "resource_groups": {
      "rg1": {
        "name": "example-rg",
        "location": "eastus"
      }
    },
    "storage": {
      "storage_accounts": {
        "sa1": {
          "name": "examplesa1",
          "resource_group_key": "rg1",
          "tier": "Standard",
          "replication_type": "LRS",
          "network_rules": {
            "default_action": "Deny",
            "ip_rules": ["1.2.3.4/32"],
            "subnet_keys": ["vnet1_subnet1"]
          }
        }
      }
    }
  }
}
```

## Testing

1. **Pruebas Unitarias**
```hcl
module "test_storage" {
  source = "./modules/storage"

  configuration = {
    storage_accounts = {
      "test_sa" = {
        name                = "testsa"
        resource_group_key = "rg1"
        tier               = "Standard"
        replication_type   = "LRS"
      }
    }
  }

  resource_group_ids = {
    "rg1" = "test-rg"
  }

  subnet_ids = {}
}
```

2. **Pruebas de Integración**
   - Probar con el orquestador completo
   - Verificar referencias cruzadas
   - Validar outputs en el orquestador

## Consideraciones de Seguridad

1. **Manejo de Secretos**
   - Marcar variables sensibles
   - No exponer secretos en outputs no sensibles
   - Usar Key Vault para secretos cuando sea posible

2. **Control de Acceso**
   - Implementar reglas de red por defecto restrictivas
   - Documentar permisos IAM requeridos
   - Validar entradas para prevenir configuraciones inseguras 