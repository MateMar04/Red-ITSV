# Migracion de ZeroShell a MikroTik CCR2004

Este documento resume la configuracion recuperada del backup y describe como aplicar el archivo `mikrotik-ccr2004-config.rsc` en la CCR2004-16G-2S+.

## 1. Resumen de la configuracion original

- **Hostname**: `panca.itsv.edu.ar`.
- **Interfaces**:
  - ETH00 (WAN) con IP publica `181.10.31.114/29` y gateway `181.10.31.113`.
  - ETH01 (LAN) con `192.168.0.1/24`.
  - VPN99 (OpenVPN) con gateway `192.168.250.254/24` para clientes `192.168.250.1-253` (servicio deshabilitado en el backup).
- **DNS interno**: ZeroShell ejecutaba BIND con recursion habilitada para redes privadas y reenviaba la zona `virtual.itsv.edu.ar` a `192.168.0.70`. Se forzaba `nameserver 1.1.1.1` en `/etc/resolv.conf`.
- **NTP**: cliente habilitado contra `0-3.pool.ntp.org` y zona horaria `Europe/Rome`.
- **NAT**: mascarade desde redes internas hacia WAN.
- **Servicios extra**: No se encontraron DHCP ni port forwarding activos. El servicio OpenVPN estaba configurado pero deshabilitado.
- **Alerta seguridad**: El script `Database/var/register/system/startup/chron` descarga binarios externos y configura cron jobs sospechosos. Se recomienda NO replicarlo.

## 2. Aplicar el script de configuracion

1. Desde Winbox o consola, haga un backup de fabrica si desea conservar la configuracion default.
2. Ejecute `/system reset-configuration no-defaults=yes skip-backup=yes` para iniciar desde cero.
3. Suba `mikrotik-ccr2004-config.rsc` al router (Winbox > Files, FTP o `tool fetch`).
4. Importe el archivo:
   ```bash
   /import file-name=mikrotik-ccr2004-config.rsc
   ```
5. Verifique que las interfaces fisicas coinciden con su cableado. El script asume `ether1` = WAN e `ether2` = LAN.
6. Agregue puertos adicionales al bridge LAN si es necesario:
   ```bash
   /interface bridge port add bridge=bridge-lan interface=ether3
   ```

## 3. Acciones adicionales recomendadas

- **Usuarios VPN**: Cree secretos con `/ppp secret add name=usuario password=clave profile=ovpn-profile service=ovpn`.
- **Certificados**: Importe el certificado del servidor y la CA ubicados en `Database/etc/ssl/certs/panca.itsv.edu.ar_host.pem` y `Database/etc/ssl/certs/cacert.pem`. Asigne el certificado al servidor OpenVPN y habilitelo cuando haya validado usuarios.
- **DNS externos**: Si necesita otros resolutores ademas de Cloudflare, agreguelos con `/ip dns set servers=IP1,IP2`.
- **Acceso de gestion remoto**: Ajuste `ip firewall filter` o `ip service set winbox address=` si requiere administrar desde Internet.
- **Scripts heredados**: No migre los scripts detectados como maliciosos (`chron`, `linuxd86`, `whatchdog`). Utilice herramientas legitimas de monitoreo en su lugar.

## 4. Verificacion basica

1. Confirme IPs:
   ```bash
   /ip address print where interface~"ether1|bridge-lan|loopback-ovpn"
   ```
2. Probar salida a Internet desde el router (`/tool ping 8.8.8.8`).
3. Validar resolucion DNS (`/tool dns-update name=www.google.com`).
4. Verificar NAT (`/ip firewall nat print where comment~"NAT interno"`).
5. Revisar reglas de firewall y counters (`/ip firewall filter print stats`).
6. Si habilita OpenVPN, haga pruebas con un cliente y confirme que recibe IP del pool y tiene salida a Internet.

## 5. Notas de seguridad

- Cambie las credenciales por defecto (`admin` sin password) inmediatamente.
- Considere restringir Winbox/SSH a redes de confianza adicionales mediante `address-list`.
- Mantenga RouterOS y RouterBOOT actualizados.
- Supervise regularmente los scripts configurados en `system scheduler` o `files` para evitar repeticion de compromisos como el observado en el backup.
