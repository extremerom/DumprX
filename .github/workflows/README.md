# Workflow de Creación de Dump de Dispositivo

Este workflow de GitHub Actions permite crear un dump de un dispositivo de forma automatizada.

## Cómo usar el workflow

1. Ve a la pestaña **Actions** de este repositorio
2. Selecciona el workflow **"Create Device Dump"** en el panel izquierdo
3. Haz clic en el botón **"Run workflow"** en el lado derecho
4. Completa los siguientes campos requeridos:

### Parámetros de entrada

#### 1. URL del dump del firmware
- **Campo**: `dump_url`
- **Descripción**: URL donde se encuentra el archivo de firmware a procesar
- **Formatos soportados**:
  - Enlaces directos de descarga
  - mega.nz
  - mediafire.com
  - drive.google.com
  - onedrive
  - androidfilehost.com
- **Ejemplo**: `'https://mega.nz/file/abcd1234'`
- **Nota**: Debe estar entre comillas simples si contiene caracteres especiales

#### 2. URL del repositorio de destino
- **Campo**: `repo_url`
- **Descripción**: URL del repositorio de GitHub donde se subirá el dump
- **Formato**: `https://github.com/usuario/nombre-repositorio`
- **Ejemplo**: `https://github.com/myorg/device-dump`
- **Nota**: El workflow extraerá automáticamente el nombre de usuario/organización de esta URL

#### 3. Token de GitHub
- **Campo**: `github_token`
- **Descripción**: Token de acceso personal de GitHub con permisos de escritura
- **Permisos necesarios**:
  - `repo` (acceso completo a repositorios)
  - `workflow` (si se necesita actualizar workflows)
- **Cómo crear un token**:
  1. Ve a GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
  2. Haz clic en "Generate new token (classic)"
  3. Selecciona los permisos `repo`
  4. Genera y copia el token
- **Nota**: Este token se mantendrá seguro y no se mostrará en los logs

## Proceso del workflow

El workflow realiza los siguientes pasos:

1. **Checkout del repositorio**: Descarga el código de DumprX
2. **Configuración de Python**: Instala Python 3.9
3. **Instalación de dependencias**: Instala todas las herramientas necesarias para procesar el firmware
4. **Instalación de uv**: Instala el gestor de paquetes Python uv
5. **Configuración de Git**: Configura el usuario de Git para hacer commits
6. **Configuración del token**: Guarda el token de GitHub en un archivo `.github_token`
7. **Extracción del nombre de organización**: Extrae automáticamente el nombre de usuario/organización del repositorio de destino
8. **Ejecución del dumper**: Ejecuta el script `dumper.sh` con la URL del firmware
9. **Subida de artefactos** (solo si falla): Si el proceso falla, sube los archivos generados como artefactos

## Formatos de firmware soportados

El script soporta múltiples formatos de firmware:
- `.zip`, `.rar`, `.7z`, `.tar`, `.tar.gz`, `.tgz`, `.tar.md5`
- `.ozip`, `.ofp`, `.ops` (Oppo/OnePlus)
- `.kdz` (LG)
- `ruu_*.exe` (HTC)
- `system.new.dat`, `system.new.dat.br`, `system.new.dat.xz`
- `system.img`, `system-sign.img`, `UPDATE.APP`
- `*.emmc.img`, `*.img.ext4`, `system.bin`, `system-p`
- `payload.bin` (OTA A/B)
- `*.nb0`, `*chunk*`, `*.pac`, `*super*.img`, `*system*.sin`

## Resultado

Una vez completado el workflow:
- El dump del firmware se subirá automáticamente al repositorio especificado
- Se creará una nueva rama con el nombre basado en la descripción del firmware
- Se generarán archivos como:
  - `README.md` con información del dispositivo
  - `all_files.txt` con lista de todos los archivos
  - `proprietary-files.txt` con lista de archivos propietarios
  - Árboles de dispositivo TWRP y AOSP (si aplica)
  - Particiones extraídas (system, vendor, boot, etc.)

## Solución de problemas

### El workflow falla durante la descarga
- Verifica que la URL del firmware sea correcta y accesible
- Para URLs de mega.nz, mediafire, etc., asegúrate de que el enlace sea público

### Error de permisos al subir al repositorio
- Verifica que el token de GitHub tenga los permisos correctos
- Asegúrate de que el repositorio de destino existe o que tienes permisos para crearlo

### El workflow tarda mucho tiempo
- Los archivos de firmware grandes pueden tardar en descargarse y procesarse
- El workflow tiene un límite de tiempo de 6 horas

## Opciones adicionales (opcional)

Si deseas recibir notificaciones en Telegram cuando se complete el dump, puedes crear:
- Un archivo `.tg_token` con tu token de bot de Telegram
- Un archivo `.tg_chat` con tu ID de chat/canal de Telegram

Estos archivos deben agregarse al repositorio antes de ejecutar el workflow.
