# Guía del Workflow de Creación de Dumps

## ✅ Implementación Completada

Se ha creado exitosamente un workflow de GitHub Actions que permite crear dumps de dispositivos automáticamente.

## 📋 Archivos Creados

1. `.github/workflows/dump-device.yml` - El workflow principal
2. `.github/workflows/README.md` - Documentación completa en español

## 🎯 Parámetros Implementados

El workflow solicita exactamente los tres parámetros requeridos:

### 1. URL del Dump (`dump_url`)
- **Qué es**: La URL donde se encuentra el archivo de firmware a procesar
- **Formatos soportados**: mega.nz, mediafire, gdrive, onedrive, androidfilehost, enlaces directos
- **Cómo se usa**: Se pasa como argumento al script dumper.sh

### 2. URL del Repositorio (`repo_url`)
- **Qué es**: La URL del repositorio de GitHub donde se subirá el dump
- **Formato**: https://github.com/usuario/repositorio
- **Cómo se usa**: El workflow extrae automáticamente el nombre de usuario/organización y lo guarda en `.github_orgname`

### 3. Token de GitHub (`github_token`)
- **Qué es**: Un token de acceso personal de GitHub con permisos de escritura
- **Permisos necesarios**: `repo` (acceso completo a repositorios)
- **Cómo se usa**: Se guarda en `.github_token` que el script dumper.sh utiliza para subir el dump

## 🚀 Cómo Usar el Workflow

1. Ve a la pestaña **Actions** del repositorio
2. Selecciona **"Create Device Dump"** en el panel izquierdo
3. Haz clic en **"Run workflow"**
4. Completa los tres campos:
   - **dump_url**: URL del firmware (ej: `https://mega.nz/file/abc123`)
   - **repo_url**: URL del repo destino (ej: `https://github.com/miorg/mi-dump`)
   - **github_token**: Tu token de GitHub
5. Haz clic en **"Run workflow"**

## 🔍 Cómo Funciona Internamente

```
Usuario → GitHub Actions → Workflow
                              ↓
                    1. Instala dependencias
                    2. Configura Git
                    3. Guarda token → .github_token
                    4. Extrae org → .github_orgname
                    5. Ejecuta dumper.sh
                              ↓
                    dumper.sh lee .github_token y .github_orgname
                              ↓
                    Descarga → Extrae → Sube a GitHub
```

## 🔒 Seguridad

El workflow implementa las mejores prácticas de seguridad:

- ✅ Token enmascarado en logs (no se muestra en la salida)
- ✅ Uso de variables de entorno (evita inyección de comandos)
- ✅ Permisos explícitos y mínimos
- ✅ Sin vulnerabilidades según CodeQL
- ✅ Sin alertas de seguridad

## 📦 Dependencias Instaladas Automáticamente

El workflow instala todas las herramientas necesarias:
- Herramientas de compresión: 7z, rar, zip, unzip, p7zip
- Herramientas de Android: device-tree-compiler, simg2img, lpunpack
- Utilidades: aria2, axel (descargadores), detox (limpieza de nombres)
- Python y uv (gestor de paquetes Python)
- Git LFS (para archivos grandes)

## 🎓 Ejemplo de Uso

```yaml
Inputs en la interfaz de GitHub:
- dump_url: https://mega.nz/file/xxxx
- repo_url: https://github.com/myorg/xiaomi-dump
- github_token: ghp_xxxxxxxxxxxx

Resultado:
- El firmware se descarga de mega.nz
- Se extrae y procesa automáticamente
- Se sube a https://github.com/myorg/xiaomi-dump
- Se crea una nueva rama con el nombre del firmware
```

## 📚 Referencias

- Documentación completa: `.github/workflows/README.md`
- Script principal: `dumper.sh`
- Script de configuración: `setup.sh`

## ⚠️ Notas Importantes

1. El workflow puede tardar entre 30 minutos y 2 horas dependiendo del tamaño del firmware
2. El límite de tiempo es de 6 horas por ejecución
3. Si el proceso falla, los archivos generados se guardan como artefactos por 7 días
4. El token debe tener permisos para crear repositorios (si el repo no existe)

