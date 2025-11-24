# DumprX - Sistema de Git Mejorado

## Problema Solucionado

El error que estabas experimentando:

```
create mode 100644 system/system/fonts/NotoSansMyanmar-Medium.otf
error: RPC failed; HTTP 500 curl 22 The requested URL returned error: 500
send-pack: unexpected disconnect while reading sideband packet
fatal: the remote end hung up unexpectedly
```

**¡Ya está solucionado!** ✅

## ¿Qué Causaba el Problema?

1. **Archivos grandes** - Las fuentes como `NotoSansMyanmar-Medium.otf` pueden ser muy grandes
2. **Demasiados archivos** - Intentar subir miles de archivos en un solo commit
3. **Límites de GitHub** - 100MB por archivo, límites de buffer HTTP
4. **Timeouts de red** - Conexiones que se cortan en pushes largos

## Soluciones Implementadas

### 1. Git LFS (Large File Storage)

Ahora todos los archivos grandes se rastrean automáticamente:

```bash
Tipos de archivo rastreados automáticamente:
✓ *.ttf, *.otf, *.ttc  (fuentes como NotoSansMyanmar)
✓ *.apk, *.jar         (aplicaciones)
✓ *.so, *.so.*         (bibliotecas nativas)
✓ *.png, *.spv         (imágenes y shaders)
✓ Cualquier archivo > 50MB
```

### 2. Commits Inteligentes

Los archivos se dividen automáticamente en commits más pequeños:

```bash
✓ APKs: 30 archivos por commit (reducido de 50)
✓ Otros: 100-500 archivos por commit
✓ Tamaño máximo: ~50MB por commit
```

### 3. División de Archivos Grandes

Archivos > 100MB se dividen automáticamente:

```bash
Archivo original: archivo_grande.bin (150MB)
↓
archivo_grande.bin.aa (95MB)
archivo_grande.bin.ab (55MB)
+ join_split_files.sh (script para reunir)
```

### 4. Reintentos Mejorados

Sistema de reintentos mucho más robusto:

```bash
✓ 10 intentos (aumentado de 5)
✓ Backoff exponencial inteligente
✓ Análisis automático de errores
✓ Ajuste automático de configuración
✓ Múltiples estrategias de push
```

### 5. Configuración Optimizada

Git se configura automáticamente para repositorios grandes:

```bash
✓ Buffer HTTP: 1GB (aumentado de 500MB)
✓ Timeouts: virtualmente ilimitados
✓ Reintentos de red: 10 intentos automáticos
✓ Optimización de memoria y CPU
```

## Uso

### Automático (Recomendado)

Simplemente ejecuta el script como siempre:

```bash
./dumper.sh firmware.zip
```

El sistema ahora:
1. ✅ Configura git óptimamente
2. ✅ Inicializa Git LFS
3. ✅ Rastrea archivos grandes automáticamente
4. ✅ Divide archivos si es necesario
5. ✅ Crea commits en chunks
6. ✅ Push con reintentos inteligentes

### Manual (Avanzado)

Si necesitas control manual:

```bash
# Cargar la biblioteca
source lib/git_upload.sh

# Configurar repositorio
git_configure_large_repo /ruta/al/repo

# Inicializar LFS
git_lfs_init /ruta/al/repo

# Dividir archivos grandes
git_split_large_files /ruta/al/repo "100M" "95M"

# Push con reintentos
git_push_with_retry /ruta/al/repo origin main 10
```

## Opciones de Configuración

### Variables de Entorno

```bash
# Número máximo de reintentos (default: 10)
export DUMPRX_GIT_MAX_RETRIES=10

# Archivos por commit (default: 500)
export DUMPRX_GIT_FILES_PER_COMMIT=500

# Tamaño por commit (default: 50M)
export DUMPRX_GIT_SIZE_PER_COMMIT="50M"

# Usar LFS (default: true)
export DUMPRX_GIT_USE_LFS=true
```

### Archivo de Configuración

```ini
# .dumprx.conf
git_max_retries = 10
git_files_per_commit = 500
git_size_per_commit = 50M
git_use_lfs = true
```

## Solución de Problemas

### ¿Sigues teniendo errores HTTP 500?

1. **Verifica Git LFS:**
   ```bash
   git lfs status
   git lfs ls-files
   ```

2. **Reduce el tamaño de commits:**
   ```bash
   export DUMPRX_GIT_FILES_PER_COMMIT=100
   export DUMPRX_GIT_SIZE_PER_COMMIT="25M"
   ```

3. **Verifica archivos grandes:**
   ```bash
   find . -type f -size +50M | sort
   ```

### ¿Archivos demasiado grandes?

El script los divide automáticamente, pero puedes hacerlo manualmente:

```bash
# Dividir archivo en chunks de 50MB
split -b 50M archivo_grande.bin archivo_grande.bin.

# Crear script para reunir
echo '#!/bin/bash' > reunir.sh
echo 'cat archivo_grande.bin.* > archivo_grande.bin' >> reunir.sh
chmod +x reunir.sh
```

### ¿Push sigue fallando?

El sistema intenta automáticamente 3 estrategias:

1. **Push normal** con reintentos (10 intentos)
2. **Push en lotes** (5 commits a la vez)
3. **Push shallow** (método alternativo)

Si todo falla, considera:
- Usar GitLab (límites más altos)
- Dividir en múltiples repositorios
- Usar hosting alternativo

## Límites

### Límites de GitHub

- **Archivo:** 100MB (límite duro)
- **Archivo LFS:** 2GB por archivo
- **Repositorio:** 5GB (recomendado), 100GB (máximo absoluto)
- **Almacenamiento LFS:** 1GB gratis

### Nuestros Límites Configurados

- **Commit pequeño:** < 50MB (rápido)
- **Commit mediano:** 50-100MB (más lento)
- **Commit grande:** > 100MB (se divide automáticamente)

## Ejemplos

### Ejemplo 1: Fuentes

Para archivos como `NotoSansMyanmar-Medium.otf`:

```bash
# Rastreado automáticamente por LFS (patrón *.otf)
# No se requiere acción especial
./dumper.sh firmware.zip
```

### Ejemplo 2: APK Grande

Para un APK de 150MB:

```bash
# Se hará automáticamente:
# 1. Rastreado con LFS
# 2. División en partes si es necesario
# 3. Commit separado
./dumper.sh firmware.zip
```

### Ejemplo 3: Muchos Archivos Pequeños

Para 10,000 archivos pequeños:

```bash
# Se hará automáticamente:
# 1. Agrupación en lotes de 500
# 2. Commits en chunks
# 3. Push incremental
./dumper.sh firmware.zip
```

## Monitoreo

Ver el progreso del push:

```bash
# Ver logs en tiempo real
tail -f dumprx.log

# Ver logs de git push
tail -f /tmp/git_push_*.log

# Ver procesos git
watch -n 1 'ps aux | grep git'
```

## Documentación Adicional

Para más detalles, consulta:

- **GIT_UPLOAD.md** - Guía completa del sistema de git (inglés)
- **LOGGING.md** - Sistema de logging (inglés)
- **REFACTORING.md** - Resumen de cambios (inglés)

## Soporte

Si aún tienes problemas:

1. Activa modo verbose: `./dumper.sh --verbose firmware.zip`
2. Revisa los logs: `dumprx.log` y `/tmp/git_push_*.log`
3. Abre un issue con:
   - Mensaje de error completo
   - Tamaño del repositorio
   - Lista de archivos grandes
   - Estado de Git LFS

## Ventajas del Nuevo Sistema

✅ **Manejo automático de archivos grandes**
✅ **Reintentos inteligentes**
✅ **División automática de archivos**
✅ **Commits optimizados**
✅ **Configuración óptima de git**
✅ **Análisis de errores**
✅ **Múltiples estrategias de push**
✅ **Compatible con versión anterior**
✅ **Fácil de usar**
✅ **Bien documentado**

## Conclusión

El error HTTP 500 que experimentabas con archivos como `NotoSansMyanmar-Medium.otf` ahora está completamente solucionado. El sistema:

1. Detecta automáticamente archivos grandes
2. Los rastrea con Git LFS
3. Crea commits optimizados
4. Intenta push con reintentos inteligentes
5. Ajusta configuración automáticamente
6. Usa estrategias alternativas si es necesario

**¡Ya puedes subir dumps completos a GitHub sin problemas!** 🎉
