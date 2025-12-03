# Solución para GitLab con Repositorios de Usuario

## Problema Identificado

Cuando se intentaba usar el workflow con un repositorio personal de GitLab (ej: `https://gitlab.com/Eduardob3677/A.git`), el script se quedaba estancado porque:

1. **El script asumía que todos los namespaces de GitLab eran grupos**
2. Intentaba crear subgrupos bajo el usuario `Eduardob3677`
3. **GitLab no permite subgrupos en namespaces de usuario** - solo en grupos
4. El API de GitLab devolvía errores o valores nulos, causando que el script se colgara

## Diferencia entre Usuario y Grupo en GitLab

### Namespace de Usuario (Personal)
- **Ejemplo**: `gitlab.com/Eduardob3677/proyecto`
- **Características**:
  - No puede tener subgrupos
  - Los proyectos se crean directamente bajo el usuario
  - Es el namespace personal de cada usuario
  
### Namespace de Grupo (Organización)
- **Ejemplo**: `gitlab.com/mi-organizacion/marca/proyecto`
- **Características**:
  - Puede tener subgrupos ilimitados
  - Permite estructura jerárquica
  - Es compartido entre múltiples usuarios

## Solución Implementada

### Detección Automática de Tipo de Namespace

El script ahora detecta automáticamente si estás usando un namespace de usuario o de grupo:

```bash
# Intenta obtener información del grupo
GRP_RESPONSE=$(curl -s --request GET --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    "${GITLAB_HOST}/api/v4/groups/${GIT_ORG}")
GRP_ID=$(echo "${GRP_RESPONSE}" | jq -r '.id')

# Si group ID es null o vacío, es un namespace de usuario
if [[ -z "${GRP_ID}" ]] || [[ "${GRP_ID}" == "null" ]]; then
    # Lógica para namespace de usuario
else
    # Lógica para namespace de grupo (existente)
fi
```

### Para Namespaces de Usuario

Cuando se detecta un namespace de usuario:

1. **Obtiene el ID del usuario** usando el API de GitLab
2. **Crea el proyecto directamente** sin intentar crear subgrupos
3. **Formato del nombre**: `${brand}_${codename}` (ej: `xiaomi_miatoll`)
4. **URL resultante**: `gitlab.com/Eduardob3677/xiaomi_miatoll`

```bash
# Para usuario: gitlab.com/Eduardob3677/A.git
# Proyecto creado: gitlab.com/Eduardob3677/xiaomi_miatoll
```

### Para Namespaces de Grupo

Cuando se detecta un namespace de grupo (comportamiento original):

1. **Crea un subgrupo** con el nombre de la marca
2. **Crea el proyecto** dentro del subgrupo
3. **Formato**: `grupo/marca/codename`
4. **URL resultante**: `gitlab.com/mi-grupo/xiaomi/miatoll`

```bash
# Para grupo: gitlab.com/mi-organizacion/proyecto.git
# Proyecto creado: gitlab.com/mi-organizacion/xiaomi/miatoll
```

## Cómo Usar

### 1. Configurar SSH Key

La SSH key debe agregarse a GitLab exactamente como se muestra en los secrets:

```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAACFwAAAAdzc2gtcn
... (resto de la clave) ...
-----END OPENSSH PRIVATE KEY-----
```

**Importante**: 
- Incluir las líneas `BEGIN` y `END`
- Sin espacios extra al inicio o final
- La clave completa en un solo bloque

### 2. Ejecutar el Workflow

En GitHub Actions:

1. Ve a **Actions** → **Create Device Dump**
2. Click en **Run workflow**
3. Completa los campos:
   - **dump_url**: URL del firmware
   - **platform**: Selecciona `gitlab`
   - **repo_url**: URL del repositorio de GitLab (ej: `https://gitlab.com/Eduardob3677/A.git`)
   - **github_token**: (no se usa para GitLab, dejar vacío)

### 3. Resultado Esperado

El script ahora:

1. ✅ Detecta que `Eduardob3677` es un usuario (no un grupo)
2. ✅ Obtiene el ID del usuario desde el API de GitLab
3. ✅ Crea el proyecto directamente: `Eduardob3677/marca_codename`
4. ✅ Sube los commits usando SSH
5. ✅ Finaliza exitosamente

## Logs de Ejemplo

### Namespace de Usuario (NUEVO)

```
[INFO] Detected user namespace: Eduardob3677
[INFO] Creating project xiaomi_miatoll in user namespace Eduardob3677
[SUCCESS] GitLab project created/found with ID: 12345
[INFO] Project URL: https://gitlab.com/Eduardob3677/xiaomi_miatoll
```

### Namespace de Grupo (EXISTENTE)

```
[INFO] Detected group namespace: mi-organizacion
[INFO] Creating subgroup xiaomi under group mi-organizacion
[SUCCESS] GitLab project created/found with ID: 12345
[INFO] Project URL: https://gitlab.com/mi-organizacion/xiaomi/miatoll
```

## Validación y Manejo de Errores

El script ahora incluye validación robusta:

1. **Validación de PROJECT_ID**: Verifica que el proyecto se creó correctamente
2. **Fallback a proyecto existente**: Si la creación falla, intenta usar un proyecto existente
3. **Mensajes de error claros**: Indica exactamente qué falló y por qué

```bash
# Validate PROJECT_ID was successfully obtained
if [[ -z "${PROJECT_ID}" ]] || [[ "${PROJECT_ID}" == "null" ]]; then
    log_error "Failed to create or retrieve GitLab project"
    log_error "PROJECT_ID is empty or null"
    log_error "Please check your GitLab token permissions and try again"
    exit 1
fi
```

## Requisitos de Permisos del Token

Tu token de GitLab debe tener estos permisos:

- ✅ **api** - Acceso completo al API
- ✅ **write_repository** - Escribir en repositorios
- ✅ **read_user** - Leer información de usuario

## Troubleshooting

### "Could not find user or group: Eduardob3677"

**Causa**: El token no tiene permisos o el nombre de usuario es incorrecto.

**Solución**:
1. Verifica que el nombre de usuario sea correcto
2. Verifica que el token tenga los permisos necesarios
3. Prueba el token manualmente:
   ```bash
   curl --header "PRIVATE-TOKEN: tu-token" \
        "https://gitlab.com/api/v4/users?username=Eduardob3677"
   ```

### "namespace is not valid" Error

**Causa**: Este error ocurría cuando se intentaba especificar el namespace_id de un usuario al crear un proyecto.

**Solución**: Este problema ha sido corregido. Ahora, al crear proyectos en namespaces de usuario, el script omite el parámetro `namespace_id` y GitLab automáticamente usa el namespace del usuario autenticado.

### "PROJECT_ID is empty or null"

**Causa**: Falló la creación del proyecto.

**Solución**:
1. Verifica que el token tenga permisos para crear proyectos
2. Verifica que no exista ya un proyecto con ese nombre
3. Revisa los logs para ver el error exacto del API

### SSH Key No Funciona

**Causa**: La clave SSH no está configurada correctamente.

**Solución**:
1. Verifica que la clave incluya las líneas BEGIN/END
2. Agrega la clave pública a tu cuenta de GitLab
3. Prueba la conexión:
   ```bash
   ssh -T git@gitlab.com
   ```

## Archivos Modificados

### `dumper.sh` (líneas 2242-2360)

**Cambios principales**:
- Detección de tipo de namespace (usuario vs grupo)
- Lógica separada para cada tipo
- Validación robusta de PROJECT_ID
- Manejo de proyectos existentes

### `lib/git_upload.sh` (líneas 446, 475)

**Cambios menores**:
- Mensajes genéricos (no específicos de GitHub)
- Compatible con GitHub y GitLab

## Compatibilidad

✅ **Namespace de usuario de GitLab** (NUEVO)
✅ **Namespace de grupo de GitLab** (EXISTENTE)
✅ **GitHub con organización** (EXISTENTE)
✅ **GitHub con usuario personal** (EXISTENTE)

## Próximos Pasos

Si encuentras algún problema:

1. Revisa los logs del workflow
2. Verifica los permisos del token
3. Asegúrate de que la SSH key esté correctamente configurada
4. Abre un issue con:
   - Logs completos
   - URL del repositorio
   - Tipo de namespace (usuario o grupo)

## Ejemplos Reales

### Ejemplo 1: Usuario Personal

```yaml
Inputs:
  platform: gitlab
  repo_url: https://gitlab.com/Eduardob3677/A.git

Resultado:
  Proyecto creado: gitlab.com/Eduardob3677/xiaomi_miatoll
  Estructura: usuario/proyecto
```

### Ejemplo 2: Grupo/Organización

```yaml
Inputs:
  platform: gitlab
  repo_url: https://gitlab.com/dumps-firmware/proyecto.git

Resultado:
  Proyecto creado: gitlab.com/dumps-firmware/xiaomi/miatoll
  Estructura: grupo/subgrupo/proyecto
```

## Conclusión

El problema donde el workflow se quedaba estancado al usar repositorios personales de GitLab está **completamente resuelto**. El sistema ahora:

1. ✅ Detecta automáticamente el tipo de namespace
2. ✅ Usa la estrategia correcta para cada caso
3. ✅ Valida la creación del proyecto
4. ✅ Proporciona mensajes de error claros
5. ✅ Es compatible con todas las configuraciones

**¡Ahora puedes usar tanto namespaces de usuario como de grupo en GitLab sin problemas!** 🎉
