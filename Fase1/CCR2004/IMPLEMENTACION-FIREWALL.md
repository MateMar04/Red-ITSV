# Implementacion de Firewall DNS - ITS Villada

## Descripcion general

Sistema de filtrado de contenido para la red del colegio basado en dos capas complementarias:

| Capa | Que bloquea | Cantidad aproximada |
|------|-------------|---------------------|
| **CleanBrowsing DNS** (externo) | adult, porn, proxies, VPNs | ~2.000.000 dominios |
| **Blacklist local** (en el MikroTik) | gambling, games, dating, social networks, cryptojacking, malware, phishing, hacking, violencia, material peligroso | ~100.000 dominios |
| **Reglas de firewall** | DNS over TLS, DNS over HTTPS (anti-bypass) | N/A |

### Por que dos capas?

La categoria `adult` sola tiene mas de 2 millones de dominios. Si cargamos todo eso como entradas DNS estaticas en el MikroTik, el router se queda sin memoria. Por eso, delegamos el filtrado de adult/porn a **CleanBrowsing Family Filter** (servicio DNS gratuito especializado en filtrado familiar) y usamos la blacklist local solo para las categorias adicionales que el colegio necesita.

---

## Archivos del proyecto

```
CCR2004/
├── mikrotik-ccr2004-config.rsc     # Config principal del router (ya existente)
├── firewall-blacklist.rsc           # Config de firewall a importar en el MikroTik
├── generate-blacklist.py            # Script Python que genera la blacklist
├── blacklist-dns.rsc                # (generado) Archivo .rsc con los dominios bloqueados
└── IMPLEMENTACION-FIREWALL.md       # Este archivo
```

---

## Requisitos previos

- **MikroTik CCR2004** con RouterOS 7 (ya configurado y funcionando)
- **Un equipo en la LAN** con Python 3.9+ para ejecutar el generador (puede ser cualquier PC o servidor Linux/Mac/Windows)
- **Acceso a Internet** desde ese equipo (para descargar las listas)
- **Acceso al MikroTik** via Winbox, WebFig o SSH

---

## Paso 1: Generar la blacklist por primera vez

En un equipo de la LAN (por ejemplo `192.168.0.100`), clonar este repositorio y ejecutar:

```bash
cd Red-ITSV/Fase1/CCR2004/
python3 generate-blacklist.py
```

Esto descarga las listas de [ut1-blacklists](https://github.com/olbat/ut1-blacklists) y genera el archivo `blacklist-dns.rsc`.

### Opciones disponibles

```bash
# Generar con el limite por defecto (100.000 dominios)
python3 generate-blacklist.py

# Cambiar el limite (mas dominios = mas RAM usada en el MikroTik)
python3 generate-blacklist.py --max-domains 150000

# Especificar ruta de salida
python3 generate-blacklist.py --output /var/www/html/blacklist-dns.rsc

# Generar y servir inmediatamente por HTTP (para pruebas)
python3 generate-blacklist.py --serve 8080
```

### Categorias incluidas (por orden de prioridad)

| Prioridad | Categoria | Descripcion |
|-----------|-----------|-------------|
| Alta | malware | Sitios que distribuyen malware |
| Alta | phishing | Sitios de phishing |
| Alta | cryptojacking | Mineria de criptomonedas en el navegador |
| Media | dangerous_material | Material peligroso (explosivos, drogas) |
| Media | agressif (violence) | Contenido violento |
| Media | hacking | Herramientas y sitios de hacking |
| Media | mixed_adult | Contenido mixto adulto |
| Media | gambling | Apuestas y juegos de azar |
| Media | dating | Sitios de citas |
| Normal | games | Juegos online |
| Normal | social_networks | Redes sociales |

> **Nota:** La categoria `adult/porn` NO se incluye en la blacklist local porque CleanBrowsing ya la cubre. Si por alguna razon no usa CleanBrowsing, puede habilitarla descomentando la linea correspondiente en `generate-blacklist.py`.

### Whitelist (dominios que nunca se bloquean)

El script excluye automaticamente dominios que podrian ser falsos positivos:

- google.com, google.com.ar
- youtube.com
- wikipedia.org
- github.com
- microsoft.com, office.com, office365.com, outlook.com, live.com
- itsv.edu.ar, edu.ar
- whatsapp.com, zoom.us, meet.google.com

Para modificar la whitelist, editar la variable `WHITELIST` en `generate-blacklist.py`.

---

## Paso 2: Servir el archivo para que el MikroTik lo descargue

El MikroTik necesita poder descargar el archivo `blacklist-dns.rsc` via HTTP. Hay varias opciones:

### Opcion A: Servidor web existente (recomendado)

Si ya tiene un servidor web en la LAN (Apache, Nginx, etc.), copiar el archivo ahi:

```bash
# Ejemplo con Apache
cp blacklist-dns.rsc /var/www/html/blacklist-dns.rsc

# La URL seria: http://IP-DEL-SERVIDOR/blacklist-dns.rsc
```

### Opcion B: Servidor HTTP integrado en el script (para pruebas)

```bash
python3 generate-blacklist.py --serve 8080
```

Esto genera la blacklist y la sirve en `http://IP-DEL-EQUIPO:8080/blacklist-dns.rsc`. Util para probar, pero no es persistente (se apaga cuando se cierra el script).

### Opcion C: Servicio systemd (Linux, para produccion)

Crear el archivo `/etc/systemd/system/blacklist-server.service`:

```ini
[Unit]
Description=Servidor de blacklist DNS para MikroTik
After=network.target

[Service]
Type=simple
WorkingDirectory=/ruta/al/repo/Red-ITSV/Fase1/CCR2004
ExecStart=/usr/bin/python3 generate-blacklist.py --serve 8080
Restart=on-failure
RestartSec=60

[Install]
WantedBy=multi-user.target
```

Activar:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now blacklist-server
```

### Opcion D: Cron job + servidor web (recomendado para produccion)

Regenerar la blacklist diariamente con cron y servirla con un servidor web existente:

```bash
# Editar crontab
crontab -e

# Agregar (regenerar todos los dias a las 3:00 AM, una hora antes de que el MikroTik la descargue)
0 3 * * * /usr/bin/python3 /ruta/al/repo/Red-ITSV/Fase1/CCR2004/generate-blacklist.py --output /var/www/html/blacklist-dns.rsc >> /var/log/blacklist-gen.log 2>&1
```

---

## Paso 3: Configurar la URL en el archivo del MikroTik

Antes de importar la configuracion, editar `firewall-blacklist.rsc` y cambiar la URL del servidor:

```
:local url "http://192.168.0.100:8080/blacklist-dns.rsc"
```

Reemplazar `192.168.0.100:8080` con la IP y puerto reales del servidor donde esta el archivo.

---

## Paso 4: Importar la configuracion en el MikroTik

### 4.1 Subir el archivo al MikroTik

**Via Winbox:**
1. Abrir Winbox y conectarse al router
2. Ir a **Files**
3. Arrastrar el archivo `firewall-blacklist.rsc` a la ventana de archivos

**Via SCP (linea de comandos):**
```bash
scp firewall-blacklist.rsc admin@192.168.0.1:/
```

### 4.2 Importar la configuracion

Conectarse al MikroTik por terminal (Winbox Terminal, SSH, o WebFig Terminal) y ejecutar:

```
/import file-name=firewall-blacklist.rsc
```

Esto configura:
- DNS upstream con CleanBrowsing Family Filter
- Redireccion forzada de DNS (anti-bypass)
- Bloqueo de DoT y DoH
- Script de actualizacion automatica
- Scheduler diario a las 4:00 AM

### 4.3 Ejecutar la primera actualizacion

```
/system script run update-blacklist
```

> **Importante:** La primera importacion puede tardar varios minutos (son ~100.000 entradas). El router seguira funcionando normalmente durante este proceso, pero la terminal estara ocupada.

---

## Paso 5: Verificar que todo funciona

### Verificar el DNS configurado

```
/ip dns print
```

Debe mostrar:
```
servers: 185.228.168.168,185.228.169.168
allow-remote-requests: yes
cache-size: 4096KiB
```

### Verificar las reglas de firewall NAT

```
/ip firewall nat print where comment~"anti-bypass"
```

Debe mostrar las reglas de redireccion DNS (UDP y TCP).

### Verificar las reglas de firewall filter

```
/ip firewall filter print where comment~"anti-bypass"
```

Debe mostrar las reglas de bloqueo de DoT y DoH.

### Verificar las entradas DNS estaticas

```
/ip dns static print count-only where comment="blacklist-ut1"
```

Debe mostrar un numero cercano a 100.000.

### Verificar el scheduler

```
/system scheduler print where name="blacklist-update"
```

### Probar el bloqueo

Desde un equipo de la LAN, intentar acceder a un dominio que deberia estar bloqueado:

```bash
# Desde una PC de la LAN
nslookup pokerstarscasino.com 192.168.0.1
```

Deberia responder con NXDOMAIN (dominio no encontrado).

```bash
# Probar que CleanBrowsing bloquea adult
nslookup pornhub.com 192.168.0.1
```

Deberia responder con la IP de bloqueo de CleanBrowsing (185.228.168.254 o similar).

---

## Mantenimiento

### Actualizar la blacklist manualmente

```
/system script run update-blacklist
```

### Ver el log de actualizaciones

```
/log print where message~"Blacklist"
```

### Verificar cuanta RAM usan las entradas DNS

```
/ip dns static print count-only where comment="blacklist-ut1"
/system resource print
```

Si la RAM libre es menor al 20%, considerar reducir `--max-domains` en el generador.

### Agregar un dominio a la whitelist

Editar la variable `WHITELIST` en `generate-blacklist.py`, regenerar y esperar la proxima actualizacion (o forzarla manualmente).

### Desbloquear un dominio especifico de forma inmediata

Si necesita desbloquear un dominio sin esperar a regenerar la lista:

```
/ip dns static remove [find name="dominio-a-desbloquear.com" comment="blacklist-ut1"]
```

> **Nota:** Este cambio se revertira en la proxima actualizacion automatica. Para que sea permanente, agregarlo a la whitelist del script.

### Agregar un dominio al bloqueo de forma inmediata

```
/ip dns static add name="dominio-a-bloquear.com" type=NXDOMAIN match-subdomain=yes ttl=1h comment="blacklist-manual"
```

> **Nota:** Use el comment `blacklist-manual` (no `blacklist-ut1`) para que no se borre en la proxima actualizacion automatica.

---

## Troubleshooting

### El MikroTik no puede descargar la blacklist

1. Verificar que el servidor HTTP este corriendo:
   ```bash
   curl http://192.168.0.100:8080/blacklist-dns.rsc | head -5
   ```

2. Verificar conectividad desde el MikroTik:
   ```
   /tool fetch url="http://192.168.0.100:8080/blacklist-dns.rsc" mode=http dst-path=test.rsc
   ```

3. Revisar si hay reglas de firewall que bloqueen la conexion entre el MikroTik y el servidor.

### La importacion tarda demasiado o el router se vuelve lento

Reducir la cantidad de dominios:

```bash
python3 generate-blacklist.py --max-domains 50000
```

### Un sitio que deberia funcionar esta bloqueado

1. Verificar si esta en la blacklist:
   ```
   /ip dns static print where name~"dominio.com"
   ```

2. Si aparece con comment `blacklist-ut1`, agregarlo a la whitelist del script.

3. Si no aparece, puede estar bloqueado por CleanBrowsing. En ese caso, considerar cambiar a OpenDNS FamilyShield como alternativa:
   ```
   /ip dns set servers=208.67.222.123,208.67.220.123
   ```

### Los alumnos logran saltear el filtro

Posibles metodos de bypass y como mitigarlos:

| Bypass | Mitigacion | Estado |
|--------|-----------|--------|
| Cambiar DNS manualmente | Redireccion forzada en NAT | Ya configurado |
| DNS over TLS (DoT) | Bloqueo puerto 853 | Ya configurado |
| DNS over HTTPS (DoH) | Bloqueo IPs de proveedores DoH | Ya configurado |
| VPN | Bloquear puertos VPN comunes (1194, 1723, 500, 4500) o usar address-list | No configurado |
| Proxy web | Incluido en bloqueo de CleanBrowsing | Parcial |
| Tor | Bloquear IPs de nodos Tor (requiere lista adicional) | No configurado |

Para agregar bloqueo de VPN:

```
/ip firewall filter
add chain=forward protocol=udp dst-port=1194 action=drop comment="Bloquear OpenVPN UDP"
add chain=forward protocol=tcp dst-port=1194 action=drop comment="Bloquear OpenVPN TCP"
add chain=forward protocol=tcp dst-port=1723 action=drop comment="Bloquear PPTP"
add chain=forward protocol=udp dst-port=500,4500 action=drop comment="Bloquear IPsec/IKE"
```

---

## Diagrama del flujo DNS

```
Dispositivo (PC/celular)
        |
        | Consulta DNS (puerto 53)
        v
  MikroTik CCR2004
        |
        |-- Esta en blacklist local? ---> SI ---> Responde NXDOMAIN (bloqueado)
        |
        |-- NO
        |
        v
  CleanBrowsing DNS
  (185.228.168.168)
        |
        |-- Es adult/porn/proxy? ---> SI ---> Responde IP de bloqueo
        |
        |-- NO
        |
        v
  Respuesta DNS normal (sitio permitido)
```
