# Configuracion de cliente VPN WireGuard - Red ITSV

## Requisitos previos

- Tener instalado [WireGuard](https://www.wireguard.com/install/) en tu dispositivo.
  - **Windows / macOS**: descargar desde la pagina oficial.
  - **Linux**: `sudo apt install wireguard` (Debian/Ubuntu) o `sudo dnf install wireguard-tools` (Fedora).
  - **Android / iOS**: disponible en Google Play Store y App Store.

## Paso 1: Generar las claves

Abrir una terminal y ejecutar:

```bash
wg genkey | tee privatekey | wg pubkey > publickey
```

Esto genera dos archivos:

- `privatekey` — tu clave privada (no compartir con nadie).
- `publickey` — tu clave publica (debe ser cargada en el router por un administrador).

> En la app de WireGuard para moviles o escritorio, las claves se generan automaticamente al crear un nuevo tunel.

## Paso 2: Enviar la clave publica al administrador

Enviar el contenido de `publickey` al administrador de red para que lo registre como peer en el router.

El administrador te asignara una IP dentro del rango `10.10.10.0/24` (por ejemplo `10.10.10.2`).

## Paso 3: Crear el archivo de configuracion

Crear un archivo `itsv-vpn.conf` con el siguiente contenido, reemplazando los valores indicados:

```ini
[Interface]
# Tu clave privada (contenido del archivo privatekey)
PrivateKey = <CLAVE_PRIVADA>

# IP asignada por el administrador
Address = 10.10.10.X/24

# DNS opcional (usa el del router)
DNS = 192.168.0.1

[Peer]
# Clave publica del router (proporcionada por el administrador)
PublicKey = <CLAVE_PUBLICA_DEL_ROUTER>

# IP publica del router y puerto WireGuard
Endpoint = 181.10.31.114:13231

# Rutas accesibles a traves de la VPN
# - 10.10.10.0/24: red VPN
# - 192.168.0.0/24: red LAN interna del colegio
AllowedIPs = 10.10.10.0/24, 192.168.0.0/24

# Mantener la conexion activa (importante si estas detras de NAT)
PersistentKeepalive = 25
```

### Valores a reemplazar

| Campo | Descripcion |
|---|---|
| `<CLAVE_PRIVADA>` | Contenido del archivo `privatekey` generado en el Paso 1 |
| `10.10.10.X` | IP asignada por el administrador (ej: `10.10.10.2`) |
| `<CLAVE_PUBLICA_DEL_ROUTER>` | Clave publica del router, proporcionada por el administrador |

## Paso 4: Importar la configuracion

- **App de escritorio (Windows / macOS / Linux)**: abrir WireGuard > "Importar tunel desde archivo" > seleccionar `itsv-vpn.conf`.
- **Terminal Linux**: copiar el archivo a `/etc/wireguard/itsv-vpn.conf` y activar con:

  ```bash
  sudo wg-quick up itsv-vpn
  ```

- **Movil**: crear un tunel manualmente con los datos de la configuracion, o escanear un codigo QR generado con:

  ```bash
  qrencode -t ansiutf8 < itsv-vpn.conf
  ```

## Paso 5: Verificar la conexion

Una vez activado el tunel, verificar la conectividad:

```bash
# Ping al router por la VPN
ping 10.10.10.1

# Ping al router por la LAN interna
ping 192.168.0.1
```

Si ambos responden, la VPN esta funcionando correctamente y tenes acceso a la red interna.

## Servicios accesibles via VPN

| Servicio | Direccion |
|---|---|
| Winbox (gestion del router) | `10.10.10.1` o `192.168.0.1` |
| Equipos de la LAN | `192.168.0.0/24` |

## Solucion de problemas

| Problema | Solucion |
|---|---|
| No conecta | Verificar que el puerto UDP 13231 no este bloqueado por tu red local o firewall |
| Conecta pero no llega a la LAN | Verificar que `AllowedIPs` incluya `192.168.0.0/24` |
| Conexion inestable | Asegurar que `PersistentKeepalive = 25` este configurado |
| "Invalid handshake" | La clave publica del router o la tuya no coinciden con lo configurado en el peer |
