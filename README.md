# TechUStart — Servidor de desarrollo en Azure con Terraform

Infraestructura como Código para crear una VM Ubuntu Server con Apache2 en Azure, usando el provider `azurerm` ~> 4.0. Toda la configuración del despliegue se controla mediante variables definidas en `variables.tf`.

## Ruta rápida

1. Crear un archivo `terraform.tfvars` con la clave SSH pública obligatoria.
2. Ejecutar `terraform init` y `terraform apply`.
3. Verificar la IP pública con `terraform output public_ip_address`.

## Variables principales

| Variable | Descripción | Valor por defecto |
|----------|-------------|-------------------|
| `azure_region` | Región de Azure | `eastus` |
| `tamano_vm` | SKU de la máquina virtual | `Standard_B1s` |
| `project_name` | Nombre del proyecto, usado como prefijo de los recursos | `techustart` |
| `environment` | Ambiente de despliegue | `dev` |
| `common_tags` | Tags comunes aplicados a todos los recursos | `{ environment = "dev", project = "techustart" }` |
| `vnet_address_space` | Espacio de direcciones de la red virtual | `["10.0.0.0/16"]` |
| `subnet_address_prefixes` | Prefijos de direcciones de la subred | `["10.0.1.0/24"]` |
| `public_ip_allocation_method` | Método de asignación de la IP pública | `Static` |
| `public_ip_sku` | SKU de la IP pública | `Standard` |
| `nsg_rules` | Lista de reglas de seguridad del NSG | HTTP y SSH abiertos |
| `nic_private_ip_address_allocation` | Método de asignación de la IP privada | `Dynamic` |
| `admin_username` | Usuario administrador de la VM | `azureuser` |
| `ssh_public_key` | Clave pública SSH del usuario administrador | **obligatoria** |
| `os_disk_caching` | Tipo de caché del disco del sistema operativo | `ReadWrite` |
| `os_disk_storage_account_type` | Tipo de cuenta de almacenamiento del disco | `Standard_LRS` |
| `os_disk_name` | Nombre opcional del disco del sistema operativo | `${project}-${environment}-osdisk` |
| `os_image` | Imagen del sistema operativo | Ubuntu Server 22.04 LTS gen2 |
| `custom_data` | Script de bootstrap en texto plano | Instala Apache2 |

## Configuración mediante `terraform.tfvars`

Crear un archivo `terraform.tfvars` en la raíz del proyecto. La única variable obligatoria es `ssh_public_key`:

```hcl
ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI..."
```

Ejemplo completo con varios valores personalizados:

```hcl
project_name   = "mi-proyecto"
environment    = "dev"
admin_username = "azureuser"
ssh_public_key = file("~/.ssh/id_ed25519.pub")

common_tags = {
  environment = "dev"
  project     = "mi-proyecto"
}
```

También es posible pasar la clave directamente por línea de comandos:

```bash
terraform apply -var="ssh_public_key=$(cat ~/.ssh/id_ed25519.pub)"
```

## Requisitos previos

1. **Cuenta de Azure activa** con una suscripción (Free Tier incluida).
2. **Azure CLI** instalado y autenticado:
   ```bash
   az login
   az account set --subscription "TU-SUSCRIPCION-ID"
   export ARM_SUBSCRIPTION_ID="TU-SUSCRIPCION-ID"
   ```
3. **Terraform CLI** instalado (>= 1.0).
4. **Par de claves SSH**. Si no se tiene:
   ```bash
   ssh-keygen -t ed25519 -C "tu-email@example.com"
   ```
   Nunca se debe commitear la clave privada.

## Uso rápido

```bash
# 1. Inicializar el proyecto y descargar el provider
terraform init

# 2. Revisar los cambios que Terraform va a aplicar
terraform plan

# 3. Crear la infraestructura
terraform apply

# 4. Ver la IP pública generada
terraform output public_ip_address
```

## Verificación

Abrir en el navegador:

```
http://<PUBLIC_IP_ADDRESS>
```

Debería mostrarse la página por defecto de Apache2.

## Conexión SSH

```bash
ssh <admin_username>@<PUBLIC_IP_ADDRESS>
```

Reemplazar `<admin_username>` por el valor de la variable `admin_username`.

## Limpieza

Para evitar costos innecesarios, destruir todos los recursos al terminar:

```bash
terraform destroy
```

## Notas importantes

- La variable `ssh_public_key` es obligatoria y no tiene valor por defecto. Sin ella, `terraform plan` y `terraform apply` fallarán.
- El NSG abre el puerto 80 para HTTP y el puerto 22 como excepción documentada de administración. En producción, restringir SSH a una IP específica o eliminar la regla.
- El estado de Terraform se guarda localmente (`terraform.tfstate`). Para trabajo colaborativo, considerar un backend remoto (Azure Storage).
