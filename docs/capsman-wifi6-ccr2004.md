# CAPsMAN WiFi 6 en MikroTik CCR2004

Esta guia implementa CAPsMAN moderno de RouterOS v7 en la CCR2004 para administrar APs WiFi 6 como hAP ax3 o cAP ax.

## Objetivo

- Crear una red WiFi separada de la LAN principal.
- Usar un mismo SSID en todos los APs para facilitar roaming entre celdas.
- Aplicar QoS centralizado desde la CCR2004.
- Dejar la red preparada para agregar un captive portal en el futuro.

## Diseno propuesto

| Elemento | Valor inicial | Nota |
| --- | --- | --- |
| Bridge LAN existente | `bridge-lan` | Se reutiliza la configuracion base de la CCR2004. |
| VLAN WiFi | `50` | Red separada para clientes WiFi. |
| Interfaz L3 | `vlan-wifi-invitados` | Gateway, DHCP, firewall y futuro HotSpot. |
| Subred WiFi | `10.50.0.0/24` | Ajustable antes de importar. |
| Gateway WiFi | `10.50.0.1` | IP de la CCR2004 en la VLAN 50. |
| SSID | `ITSV-WIFI` | Mismo SSID en 2.4 GHz y 5 GHz. |
| Seguridad | WPA2/WPA3 PSK + 802.11r | `ft=yes` ayuda a roaming rapido. |
| Aislamiento WiFi | `client-isolation=yes` | Evita trafico directo entre clientes del mismo SSID. |
| QoS total | `80M/80M` | Limite global inicial de la red WiFi. |
| QoS por cliente | `2M` subida / `5M` bajada | PCQ reparte ancho de banda por IP cliente. |

## Archivos

- `Fase1/CCR2004/capsman-wifi6-ccr2004.rsc`: configura VLAN, DHCP, firewall, QoS y CAPsMAN en la CCR2004.
- `Fase1/CCR2004/capsman-wifi6-cap-client.rsc`: deja cada hAP ax3/cAP ax como cliente CAP administrado por la CCR2004.

## Requisitos

1. CCR2004 con RouterOS v7 y menu `/interface wifi` disponible.
2. APs WiFi 6 con RouterOS v7 y paquete `wifi-qcom`.
3. Los APs deben tener conectividad L2/L3 hacia `192.168.0.1` por la LAN de gestion.
4. Los switches entre CCR2004 y APs deben transportar VLAN 50.
5. Hacer backup antes de aplicar:
   ```routeros
   /export file=backup-antes-capsman
   /system backup save name=backup-antes-capsman
   ```

> Nota: este diseno no activa `vlan-filtering=yes` en `bridge-lan` para evitar cortar la LAN actual durante el piloto. Para produccion, conviene planificar VLAN filtering y marcar explicitamente puertos trunk/access.

## Paso 1 - Preparar el script de la CCR2004

Editar `Fase1/CCR2004/capsman-wifi6-ccr2004.rsc` antes de importarlo:

- Cambiar `passphrase="CAMBIARME-WIFI-2026"`.
- Ajustar `ssid="ITSV-WIFI"` si se desea otro nombre.
- Ajustar `10.50.0.0/24` si esa red ya existe.
- Ajustar QoS:
  - `pcq-rate=2M` para subida por cliente.
  - `pcq-rate=5M` para bajada por cliente.
  - `max-limit=80M/80M` para limite total.

Importar en la CCR2004:

```routeros
/import file-name=capsman-wifi6-ccr2004.rsc
```

Verificar:

```routeros
/interface wifi capsman print
/interface wifi provisioning print
/ip dhcp-server print where name=dhcp-wifi-invitados
/queue simple print where name=QoS_WIFI_CAPSMAN
```

## Paso 2 - Configurar cada AP como CAP

En cada hAP ax3 o cAP ax, partir de configuracion limpia:

```routeros
/system reset-configuration no-defaults=yes skip-backup=yes
```

Subir `Fase1/CCR2004/capsman-wifi6-cap-client.rsc`, editar `identity` y luego importar:

```routeros
/import file-name=capsman-wifi6-cap-client.rsc
```

Verificar en el AP:

```routeros
/interface wifi cap print
/ip dhcp-client print
/interface wifi print
```

Verificar en la CCR2004:

```routeros
/interface wifi capsman remote-cap print
/interface wifi registration-table print
/ip dhcp-server lease print where server=dhcp-wifi-invitados
```

## Roaming entre APs

CAPsMAN no fuerza a un cliente a cambiar de AP; la decision final la toma el dispositivo cliente. Para mejorar el salto automatico:

- Usar el mismo SSID, seguridad y passphrase en todos los APs.
- Mantener `ft=yes` y `ft-over-ds=yes` para 802.11r.
- Evitar potencias demasiado altas, porque los clientes se quedan pegados al AP lejano.
- Priorizar 5 GHz para aulas/pasillos con alta densidad.
- Ajustar canales luego de medir interferencia real.

## Seguridad y aislamiento

El script crea reglas para:

- Permitir desde WiFi solo DNS, DHCP y NTP hacia el CCR2004.
- Bloquear gestion del CCR2004 desde clientes WiFi.
- Bloquear acceso desde WiFi hacia redes privadas internas.
- Aislar clientes WiFi entre si mediante `client-isolation=yes`.
- Permitir salida desde WiFi hacia Internet mediante la WAN.

No agregar `vlan-wifi-invitados` a la interface-list `LAN`, porque la regla existente de gestion desde LAN permitiria administrar el router desde clientes WiFi.

## Futuro captive portal

La VLAN 50 queda lista para HotSpot/captive portal. Cuando se implemente:

1. Crear el HotSpot sobre `vlan-wifi-invitados`, no sobre `bridge-lan`.
2. Definir DNS name y certificado si se usara HTTPS.
3. Crear walled garden para servicios permitidos antes del login.
4. Revisar si se usara usuario local, vouchers o RADIUS/User Manager.
5. Probar primero con un solo AP y pocos clientes.

Comandos base para una prueba futura, dejarlos deshabilitados hasta validar:

```routeros
/ip hotspot profile add name=hsprof-wifi hotspot-address=10.50.0.1 dns-name=wifi.itsv.edu.ar
/ip hotspot add name=hotspot-wifi interface=vlan-wifi-invitados address-pool=pool-wifi-invitados profile=hsprof-wifi disabled=yes
```

## Rollback

Si algo falla:

```routeros
/interface wifi capsman set enabled=no
/ip dhcp-server disable dhcp-wifi-invitados
/interface vlan disable vlan-wifi-invitados
```

Para volver completamente al estado anterior, restaurar el backup realizado antes de la implementacion.
