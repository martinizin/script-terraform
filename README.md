# TechUStart — Servidor de desarrollo en Azure con Terraform

Infraestructura como Código para crear una VM Ubuntu Server con Apache2 en Azure, usando el provider `azurerm` ~> 4.0.

## Requisitos previos

1. **Cuenta de Azure activa** con una suscripción (Free Tier incluida).
2. **Azure CLI** instalado y autenticado:
   ```bash
   az login
   az account set --subscription "TU-SUSCRIPCION-ID"
   export ARM_SUBSCRIPTION_ID="TU-SUSCRIPCION-ID"
   ```
3. **Terraform CLI** instalado (>= 1.0).
4. **Par de claves SSH** en `~/.ssh/id_rsa.pub`. Si no la tienes:
   ```bash
   ssh-keygen -t rsa -b 4096 -C "tu-email@example.com" -f ~/.ssh/id_rsa
   ```
   Nunca commitees la clave privada (`~/.ssh/id_rsa`).

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

Abre en tu navegador:

```
http://<PUBLIC_IP_ADDRESS>
```

Deberías ver la página por defecto de Apache2.

## Conexión SSH

```bash
ssh azureuser@<PUBLIC_IP_ADDRESS>
```

## Limpieza

Para evitar costos innecesarios, destruye todos los recursos al terminar:

```bash
terraform destroy
```

## Notas importantes

- El código asume que tu clave pública SSH está en `~/.ssh/id_rsa.pub`. Si usas otra ruta, modifica `main.tf` en el bloque `admin_ssh_key`.
- El NSG abre el puerto 80 para HTTP y el puerto 22 como excepción documentada de administración. En producción, restringe SSH a tu IP o elimínalo.
- El estado de Terraform se guarda localmente (`terraform.tfstate`). Para trabajo colaborativo, considera un backend remoto (Azure Storage).
