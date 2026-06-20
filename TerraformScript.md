# PRD: Automatización de Servidor de Desarrollo en Azure con Terraform

## 1. Contexto del Proyecto

**Empresa:** TechUStart
**Rol:** Ingeniero DevOps
**Objetivo de negocio:** Automatizar de manera segura y reproducible la creación de servidores de desarrollo en Azure, evitando que el script se rompa en el futuro por actualizaciones automáticas de proveedores o de internet.

## 2. Problema a Resolver

Actualmente la creación de VMs de desarrollo es manual, propensa a errores de configuración (puertos abiertos de más, credenciales inconsistentes) y no versionada. Se requiere Infraestructura como Código (IaC) con Terraform que:

- Sea determinística y reproducible (control de versiones del provider).
- Exponga únicamente el puerto necesario (HTTP/80).
- Instale automáticamente el software base (Apache) al arrancar, sin intervención manual.

## 3. Alcance (Scope)

### Incluye
- Provisión de una VM Linux (Ubuntu Server) en Azure vía Terraform.
- Red virtual, subred, IP pública y NSG con regla mínima necesaria (puerto 80).
- Bootstrap automático del servidor web Apache mediante `custom_data`.
- Output de la IP pública para validación inmediata.

### No incluye (fuera de alcance por ahora)
- Balanceadores de carga, autoescalado o múltiples VMs.
- HTTPS/TLS (certificados, puerto 443).
- Backend remoto de estado de Terraform (state en Azure Storage) — se asume estado local para este ejercicio, pero se documenta como mejora futura.
- Gestión de secretos vía Azure Key Vault (se usan claves SSH simples).

## 4. Requerimientos Funcionales

### 4.1 Archivo `variables.tf`
Debe definir exactamente:

| Variable | Tipo | Default | Descripción |
|---|---|---|---|
| `azure_region` | string | `"eastus"` | Región de despliegue de los recursos |
| `tamano_vm` | string | `"Standard_B1s"` | SKU económico/capa gratuita para la VM |

### 4.2 Archivo `main.tf`
Debe contener, **en este orden**:

1. **Bloque `terraform { }`**
   - `required_providers` con `azurerm`, version pin `~> 3.0` o `~> 4.0` (fijar una sola, no ambas, para evitar conflictos de breaking changes futuros).
2. **Bloque `provider "azurerm" { }`**
   - Debe incluir obligatoriamente `features {}` (vacío es válido, pero el bloque es requerido por el provider).
3. **`azurerm_resource_group`**
   - Contenedor lógico que agrupa todos los recursos. Usa `var.azure_region` como `location`.
4. **Red básica**
   - `azurerm_virtual_network` (ej. CIDR `10.0.0.0/16`)
   - `azurerm_subnet` (ej. CIDR `10.0.1.0/24`)
   - `azurerm_public_ip` (SKU `Standard` o `Basic`, allocation estático recomendado)
5. **`azurerm_network_security_group`**
   - Una sola `security_rule` entrante que abra **únicamente el puerto 80 (HTTP)**.
   - Prioridad, dirección `Inbound`, protocolo `Tcp`, acceso `Allow`.
   - No abrir SSH (22) salvo que se documente explícitamente como excepción de acceso administrativo.
6. **`azurerm_network_interface`**
   - Vincula la subred y la IP pública creadas anteriormente.
   - Debe asociarse al NSG (vía `azurerm_network_interface_security_group_association` o asociación directa a la subred).
7. **`azurerm_linux_virtual_machine`**
   - Imagen: Ubuntu Server de Canonical (ej. `Canonical / 0001-com-ubuntu-server-jammy / 22_04-lts-gen2` o equivalente vigente).
   - `size = var.tamano_vm`
   - Autenticación SSH con clave pública (`admin_ssh_key`), deshabilitar password authentication.
   - `custom_data`: script Bash codificado en Base64 (función `base64encode()` de Terraform) que ejecute:
     ```bash
     sudo apt update && sudo apt install apache2 -y
     ```
8. **Output**
   - Debe imprimir en terminal la IP pública asignada (`azurerm_public_ip.<nombre>.ip_address`).

## 5. Requerimientos No Funcionales

- **Estabilidad ante el tiempo:** version pinning del provider (`~> 3.0` o `~> 4.0`) para que `terraform init` no traiga automáticamente una versión mayor incompatible.
- **Seguridad mínima viable:** superficie de ataque reducida — solo el puerto 80 abierto; sin contraseñas en texto plano (usar SSH key).
- **Idempotencia:** ejecutar `terraform apply` repetidas veces no debe generar recursos duplicados ni errores.
- **Nomenclatura consistente:** todos los recursos deben usar un prefijo común (ej. `techustart-dev`) para fácil identificación y limpieza.
- **Documentación:** comentarios en el código explicando el propósito de cada bloque.

## 6. Entregables Esperados de OpenCode

1. `variables.tf` — según sección 4.1.
2. `main.tf` — según sección 4.2, completo y ejecutable.
3. (Opcional recomendado) `outputs.tf` separado si OpenCode prefiere modularizar, en vez de incluir el output dentro de `main.tf`.
4. Un archivo `README.md` corto con instrucciones de `terraform init / plan / apply / destroy`.
5. Una **guía paso a paso en Azure Portal** (no solo CLI) que cubra:
   - Cómo crear/verificar una Cuenta y Suscripción de Azure (Free Tier si aplica).
   - Cómo crear un Service Principal o configurar `az login` para que Terraform se autentique contra Azure.
   - Cómo generar el par de llaves SSH (`ssh-keygen`) si el usuario no tiene una.
   - Cómo ejecutar `terraform init`, `terraform plan`, `terraform apply`.
   - Cómo verificar en el portal de Azure que los recursos (Resource Group, VNet, NSG, VM) se crearon correctamente.
   - Cómo probar el acceso HTTP (abrir `http://<IP_PUBLICA>` en el navegador y validar la página default de Apache2).
   - Cómo conectarse por SSH a la VM para validar manualmente.
   - Cómo destruir todo con `terraform destroy` para evitar costos innecesarios.

## 7. Criterios de Aceptación

- [ ] `terraform validate` pasa sin errores.
- [ ] `terraform plan` muestra la creación de: 1 Resource Group, 1 VNet, 1 Subnet, 1 Public IP, 1 NSG (+ 1 regla), 1 NIC, 1 VM Linux.
- [ ] Tras `terraform apply`, abrir `http://<ip_publica>` en el navegador muestra la página default de Apache2 (sin necesidad de instalación manual).
- [ ] El NSG **no** expone ningún puerto distinto al 80 (verificar que 22, 3389, etc. no estén abiertos salvo decisión explícita).
- [ ] El output de Terraform imprime correctamente la IP pública tras el apply.
- [ ] El código usa `var.azure_region` y `var.tamano_vm` en los lugares correspondientes (no valores hardcodeados).

## 8. Riesgos y Mitigaciones

| Riesgo | Mitigación |
|---|---|
| Breaking changes del provider `azurerm` en versiones futuras | Pin de versión `~> 4.0` (o `~> 3.0`) en `required_providers` |
| Imagen Ubuntu deprecada con el tiempo | Documentar cómo consultar imágenes vigentes con `az vm image list` |
| Exposición accidental de puertos | Única regla NSG explícita para puerto 80; revisión en `terraform plan` antes de aplicar |
| Costos no controlados | Usar `Standard_B1s` (capa económica) y recordar `terraform destroy` al finalizar pruebas |
| Credenciales SSH hardcodeadas en el repo | Usar variable para la ruta de la clave pública, nunca commitear claves privadas |

## 9. Prompt Sugerido para OpenCode

> "Actúa como ingeniero DevOps experto en Terraform y Azure. Usando el PRD adjunto (TerraformScript.md), genera los archivos `variables.tf` y `main.tf` completos, funcionales y comentados, cumpliendo exactamente los requerimientos de la sección 4 y los criterios de aceptación de la sección 7. Luego, genera una guía paso a paso para Azure Portal y CLI según la sección 6, punto 5."

---
*Documento generado para uso como input de OpenCode — proyecto TechUStart, servidores de desarrollo Azure.*
