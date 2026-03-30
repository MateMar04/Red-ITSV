# Implementacion automatizada via GitHub - Firewall DNS

## Como funciona

```
GitHub Actions (cron diario 03:00 UTC / 00:00 ARG)
    |
    |  1. Ejecuta generate-blacklist.py
    |  2. Descarga las listas de ut1-blacklists
    |  3. Genera blacklist-dns.rsc (~500k dominios)
    |  4. Lo publica en la rama "blacklist" (force push, sin historial)
    |
    v
Rama "blacklist" en GitHub
    |
    |  URL directa (sin redirecciones):
    |  https://raw.githubusercontent.com/MateMar04/Red-ITSV/blacklist/blacklist-dns.rsc
    |
    v
MikroTik CCR2004 (scheduler diario 04:00 ARG)
    |
    |  1. /tool fetch descarga el .rsc desde GitHub
    |  2. /import ejecuta el archivo (limpia entradas viejas + agrega nuevas)
    |  3. Elimina el archivo temporal
    |
    v
~100.000 dominios bloqueados via DNS estatico (NXDOMAIN)
+ CleanBrowsing filtra adult/porn a nivel DNS upstream
```

No se necesita ningun servidor local. Todo queda automatizado entre GitHub y el MikroTik.

---

## Archivos involucrados

| Archivo | Donde corre | Que hace |
|---------|-------------|----------|
| `.github/workflows/update-blacklist.yml` | GitHub Actions | Cron diario que genera y publica la blacklist |
| `Fase1/CCR2004/generate-blacklist.py` | GitHub Actions | Script Python que descarga listas y genera el .rsc |
| `Fase1/CCR2004/firewall-blacklist-github.rsc` | MikroTik (una vez) | Configura firewall, DNS, script y scheduler |
| `blacklist-dns.rsc` | Rama `blacklist` | Archivo generado que el MikroTik descarga diariamente |

---

## Paso 1: Pushear los cambios al repositorio

Desde la maquina local, commitear y pushear los archivos nuevos:

```bash
cd Red-ITSV
git add .github/workflows/update-blacklist.yml
git add Fase1/CCR2004/generate-blacklist.py
git add Fase1/CCR2004/firewall-blacklist-github.rsc
git commit -m "Agregar sistema de blacklist DNS automatizado via GitHub Actions"
git push origin master
```

---

## Paso 2: Verificar que GitHub Actions funciona

### 2.1 Ejecutar el workflow manualmente (primera vez)

1. Ir a **https://github.com/MateMar04/Red-ITSV/actions**
2. Click en **"Actualizar Blacklist DNS"** en la barra lateral
3. Click en **"Run workflow"** → **"Run workflow"**
4. Esperar a que termine (tarda 2-3 minutos)

### 2.2 Verificar la rama blacklist

1. Ir a **https://github.com/MateMar04/Red-ITSV/tree/blacklist**
2. Deberia existir la rama con un unico archivo **blacklist-dns.rsc**

### 2.3 Verificar la URL de descarga

La URL directa del archivo es:

```
https://raw.githubusercontent.com/MateMar04/Red-ITSV/blacklist/blacklist-dns.rsc
```

Se puede probar descargandolo:

```bash
curl -o /tmp/test.rsc "https://raw.githubusercontent.com/MateMar04/Red-ITSV/blacklist/blacklist-dns.rsc"
head -15 /tmp/test.rsc
```

> **Nota:** Se usa `raw.githubusercontent.com` porque es una URL directa sin redirecciones, lo que evita problemas con `/tool fetch` de MikroTik.

---

## Paso 3: Configurar el MikroTik

### 3.1 Subir el archivo de configuracion

**Via Winbox:**
1. Abrir Winbox → conectarse al router
2. Ir a **Files**
3. Arrastrar `firewall-blacklist-github.rsc` a la ventana de archivos

**Via SCP:**
```bash
scp Fase1/CCR2004/firewall-blacklist-github.rsc admin@192.168.0.1:/
```

### 3.2 Importar la configuracion

Conectarse al MikroTik por terminal y ejecutar:

```
/import file-name=firewall-blacklist-github.rsc
```

Esto configura de una sola vez:

- DNS upstream con **CleanBrowsing Family Filter** (bloquea adult/porn)
- **Redireccion forzada** de todo el trafico DNS por el MikroTik
- **Bloqueo de DoT** (puerto 853) y **DoH** (proveedores conocidos)
- **Script** `update-blacklist` que descarga desde GitHub Releases
- **Scheduler** que ejecuta el script todos los dias a las 4:00 AM

### 3.3 Ejecutar la primera descarga

```
/system script run update-blacklist
```

> **Importante:** La primera importacion tarda varios minutos (~100.000 entradas). La terminal va a estar ocupada hasta que termine. El router sigue funcionando normalmente durante el proceso.

---

## Paso 4: Verificar que todo funciona

### En el MikroTik

```
# Verificar DNS configurado
/ip dns print

# Verificar cantidad de dominios bloqueados
/ip dns static print count-only where comment="blacklist-ut1"

# Verificar scheduler
/system scheduler print where name="blacklist-update"

# Ver logs de la ultima actualizacion
/log print where message~"Blacklist"
```

### Desde una PC de la LAN

```bash
# Deberia responder NXDOMAIN (bloqueado por blacklist local)
nslookup pokerstarscasino.com 192.168.0.1

# Deberia responder IP de bloqueo de CleanBrowsing (bloqueado por DNS upstream)
nslookup pornhub.com 192.168.0.1

# Deberia resolver normalmente (permitido)
nslookup google.com 192.168.0.1
```

---

## Mantenimiento

### La blacklist se actualiza sola?

Si. GitHub Actions genera una nueva blacklist todos los dias a las 00:00 hora Argentina, y el MikroTik la descarga a las 04:00.

### Quiero forzar una actualizacion ahora

**Desde GitHub:**
1. Ir a **Actions** → **"Actualizar Blacklist DNS"** → **"Run workflow"**

**Desde el MikroTik** (despues de que GitHub termine):
```
/system script run update-blacklist
```

### Quiero agregar un dominio a la whitelist

Editar `WHITELIST` en `Fase1/CCR2004/generate-blacklist.py`, commitear y pushear:

```python
WHITELIST = {
    "google.com",
    ...
    "nuevo-dominio.com",   # <-- agregar aca
}
```

```bash
git add Fase1/CCR2004/generate-blacklist.py
git commit -m "Agregar nuevo-dominio.com a la whitelist"
git push origin master
```

Luego ejecutar el workflow manualmente o esperar al proximo dia.

### Quiero agregar o quitar una categoria

Editar la lista `CATEGORIES` en `generate-blacklist.py`:

```python
CATEGORIES = [
    ("malware",             "alta"),
    ("phishing",            "alta"),
    ...
    # Descomentar para incluir adult (ojo: 2M de dominios, puede no caber)
    # ("adult",             "baja"),
]
```

### Quiero desbloquear un dominio de forma inmediata (sin esperar)

Desde el MikroTik:

```
/ip dns static remove [find name="dominio.com" comment="blacklist-ut1"]
```

> Este cambio se revertira en la proxima actualizacion. Para que sea permanente, agregarlo a la whitelist en el script.

### Quiero bloquear un dominio extra de forma inmediata

```
/ip dns static add name="dominio.com" type=NXDOMAIN match-subdomain=yes ttl=1h comment="blacklist-manual"
```

> Usar comment `blacklist-manual` (no `blacklist-ut1`) para que no se borre en la proxima actualizacion.

---

## Troubleshooting

### GitHub Actions no corre

1. Verificar que el workflow existe en el repositorio: ir a **Actions** y ver si aparece
2. Si el repositorio es privado, verificar que GitHub Actions esta habilitado: **Settings** → **Actions** → **General** → **Allow all actions**
3. Los scheduled workflows pueden tardar hasta 15 minutos en ejecutarse la primera vez

### El MikroTik no puede descargar desde GitHub

1. Verificar que el router tiene acceso a Internet:
   ```
   /tool fetch url="https://www.google.com" mode=https check-certificate=no dst-path=test.html
   ```

2. Verificar que el archivo existe en GitHub:
   ```
   /tool fetch url="https://raw.githubusercontent.com/MateMar04/Red-ITSV/blacklist/blacklist-dns.rsc" mode=https check-certificate=no dst-path=test.rsc
   ```

3. Si falla con error de SSL/TLS, verificar que RouterOS esta actualizado:
   ```
   /system routerboard print
   /system package update check-for-updates
   ```

4. Si el repositorio es **privado**, el MikroTik no podra descargar la release. Opciones:
   - Hacer el repositorio publico
   - Usar un servidor local como intermediario (ver `IMPLEMENTACION-FIREWALL.md`)

### La importacion es muy lenta

Reducir la cantidad de dominios editando `generate-blacklist.py`:

```python
DEFAULT_MAX_DOMAINS = 50_000  # Cambiar de 100k a 50k
```

Commitear, pushear, y esperar la proxima actualizacion.

### Cuanta RAM usa?

Cada entrada DNS estatica usa aproximadamente 200-300 bytes de RAM en RouterOS 7.

| Dominios | RAM estimada |
|----------|-------------|
| 50.000 | ~12 MB |
| 100.000 | ~25 MB |
| 150.000 | ~40 MB |

El CCR2004 tiene 4 GB de RAM, asi que 100k entradas no deberian ser un problema.

Verificar uso actual:

```
/system resource print
```

---

## Resumen de URLs importantes

| Que | URL |
|-----|-----|
| Repositorio | https://github.com/MateMar04/Red-ITSV |
| GitHub Actions | https://github.com/MateMar04/Red-ITSV/actions |
| Releases | https://github.com/MateMar04/Red-ITSV/releases |
| Descarga directa del .rsc | https://raw.githubusercontent.com/MateMar04/Red-ITSV/blacklist/blacklist-dns.rsc |
| Fuente de las listas | https://github.com/olbat/ut1-blacklists |
| CleanBrowsing | https://cleanbrowsing.org/filters/ |
