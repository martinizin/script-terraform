# Guía paso a paso — Despliegue en Azure Portal y CLI

Esta guía muestra cómo preparar tu cuenta de Azure, autenticar Terraform, crear la infraestructura y validar el servidor web.

## Ruta rápida

1. Crear/verificar cuenta de Azure y suscripción.
2. Configurar autenticación para Terraform (`az login` o Service Principal).
3. Generar par de claves SSH.
4. Ejecutar `terraform init`, `terraform plan` y `terraform apply`.
5. Verificar recursos en Azure Portal.
6. Probar HTTP y conectarse por SSH.
7. Destruir todo con `terraform destroy`.

---

## 1. Cuenta y suscripción de Azure

### Crear cuenta (si no tienes)

1. Ve a [https://azure.microsoft.com/free](https://azure.microsoft.com/free).
2. Selecciona **Comience gratis** y sigue el proceso con tu correo, teléfono y tarjeta de crédito/débito (solo para verificación; no se cobra dentro de los límites del Free Tier).
3. Una vez creada, accede al portal: [https://portal.azure.com](https://portal.azure.com).

### Verificar suscripción

1. En el portal, busca **Suscripciones** en la barra superior.
2. Asegúrate de ver una suscripción activa, por ejemplo:
   - **Visual Studio Enterprise** (si tienes beneficios MSDN).
   - **Azure for Students** o **Free Trial**.
3. Anota el **ID de suscripción**; lo necesitarás para Terraform.

---

## 2. Autenticación para Terraform

### Opción A: Inicio de sesión interactivo con Azure CLI (recomendado para pruebas)

1. Instala Azure CLI desde [https://aka.ms/installazurecliwindows](https://aka.ms/installazurecliwindows).
2. Abre una terminal y ejecuta:

   ```bash
   az login
   ```

3. Selecciona tu cuenta en el navegador.
4. Establece la suscripción activa:

   ```bash
   az account set --subscription "TU-ID-DE-SUSCRIPCION"
   ```

5. Exporta la variable de entorno requerida por el provider `azurerm` v4:

   ```bash
   # Windows (PowerShell)
   $env:ARM_SUBSCRIPTION_ID = "TU-ID-DE-SUSCRIPCION"

   # Linux / macOS / Git Bash
   export ARM_SUBSCRIPTION_ID="TU-ID-DE-SUSCRIPCION"
   ```

### Opción B: Service Principal (recomendado para CI/CD o equipos)

1. En Azure Portal, busca **Azure Active Directory** → **Registros de aplicaciones** → **Nuevo registro**.
2. Asigna un nombre, por ejemplo `techustart-terraform-sp`, y regístralo.
3. Anota el **ID de aplicación (cliente)** y el **ID de directorio (tenant)**.
4. Ve a **Certificados y secretos** → **Nuevo secreto de cliente**, descríbelo y copia el valor generado (solo se muestra una vez).
5. Ve a **Suscripciones** → tu suscripción → **Control de acceso (IAM)** → **Agregar asignación de roles**.
6. Asigna el rol **Colaborador** o **Colaborador de máquina virtual** al Service Principal.
7. Configura las variables de entorno en tu terminal:

   ```bash
   # Windows (PowerShell)
   $env:ARM_CLIENT_ID       = "ID-DE-APLICACION"
   $env:ARM_CLIENT_SECRET   = "SECRETO-DE-CLIENTE"
   $env:ARM_SUBSCRIPTION_ID = "ID-DE-SUSCRIPCION"
   $env:ARM_TENANT_ID       = "ID-DE-DIRECTORIO"

   # Linux / macOS / Git Bash
   export ARM_CLIENT_ID="ID-DE-APLICACION"
   export ARM_CLIENT_SECRET="SECRETO-DE-CLIENTE"
   export ARM_SUBSCRIPTION_ID="ID-DE-SUSCRIPCION"
   export ARM_TENANT_ID="ID-DE-DIRECTORIO"
   ```

---

## 3. Generar par de claves SSH

Si aún no tienes claves SSH, ejecuta en tu terminal:

```bash
ssh-keygen -t rsa -b 4096 -C "tu-email@example.com" -f ~/.ssh/id_rsa
```

Cuando pregunte por una contraseña, puedes dejarla en blanco para facilitar las pruebas (en producción, usa frase de paso).

Esto creará:

- `~/.ssh/id_rsa` → **clave privada, nunca la compartas ni la commitees**.
- `~/.ssh/id_rsa.pub` → clave pública, usada por Terraform para acceder a la VM.

---

## 4. Ejecutar Terraform

Desde la carpeta donde están los archivos `.tf`:

```bash
# Descarga el provider y prepara el proyecto
terraform init

# Muestra los cambios que se aplicarán (debe crear 1 RG, 1 VNet, 1 Subnet, 1 IP pública, 1 NSG, 1 NIC y 1 VM)
terraform plan

# Aplica la infraestructura. Escribe "yes" cuando lo solicite
terraform apply
```

Al finalizar, Terraform mostrará la IP pública:

```
Outputs:

public_ip_address = "20.x.x.x"
```

También puedes consultarla después con:

```bash
terraform output public_ip_address
```

---

## 5. Verificar recursos en Azure Portal

1. Abre [https://portal.azure.com](https://portal.azure.com).
2. Busca **Grupos de recursos** y selecciona `techustart-dev-rg`.
3. Dentro del grupo de recursos, confirma que existen:
   - `techustart-dev-vnet` (Red virtual, 10.0.0.0/16).
   - `techustart-dev-subnet` (Subred, 10.0.1.0/24).
   - `techustart-dev-pip` (Dirección IP pública).
   - `techustart-dev-nsg` (Grupo de seguridad de red).
   - `techustart-dev-nic` (Interfaz de red).
   - `techustart-dev-vm` (Máquina virtual).
4. Abre el NSG y revisa **Reglas de seguridad de entrada**. Debes ver:
   - `AllowHTTP` en el puerto **80**.
   - `AllowSSH` en el puerto **22** (excepción documentada de administración).
   - No debe haber reglas para el puerto 3389 ni otros puertos innecesarios.

---

## 6. Probar el acceso HTTP

1. Copia la IP pública del output de Terraform.
2. Abre tu navegador y navega a:

   ```
   http://<IP_PUBLICA>
   ```

3. Deberías ver la página por defecto de Apache2 con el mensaje **"Apache2 Ubuntu Default Page: It works"**.

> Puede tomar 1-2 minutos después del arranque para que el `custom_data` instale Apache2.

---

## 7. Conectarse por SSH para validación manual

Desde tu terminal:

```bash
ssh azureuser@<IP_PUBLICA>
```

Una vez dentro, verifica que Apache2 está activo:

```bash
sudo systemctl status apache2
```

Y revisa la página servida localmente:

```bash
curl -I http://localhost
```

Sal con:

```bash
exit
```

---

## 8. Destruir la infraestructura

Para evitar costos innecesarios, destruye todos los recursos cuando termines:

```bash
terraform destroy
```

Escribe `yes` cuando lo solicite. Al finalizar, el grupo de recursos y todos sus elementos habrán sido eliminados de Azure.

---

## Checklist de verificación

- [ ] Cuenta de Azure activa con suscripción seleccionada.
- [ ] Variables `ARM_SUBSCRIPTION_ID` (y Service Principal, si aplica) configuradas.
- [ ] Clave pública SSH presente en `~/.ssh/id_rsa.pub`.
- [ ] `terraform init` finalizó sin errores.
- [ ] `terraform plan` muestra 7 recursos a crear.
- [ ] `terraform apply` finalizó y mostró la IP pública.
- [ ] El navegador muestra la página de Apache2 en `http://<IP_PUBLICA>`.
- [ ] `terraform destroy` eliminó los recursos al terminar.

## Siguiente paso

Cuando el ejercicio esté validado, considera mover el estado de Terraform a un backend remoto (Azure Storage) para trabajo en equipo.
