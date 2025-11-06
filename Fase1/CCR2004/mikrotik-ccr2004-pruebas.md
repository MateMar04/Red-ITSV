# Plan de pruebas para la migracion ZeroShell -> MikroTik CCR2004

## 1. Preparacion
- Conectar una PC de administracion a la red LAN (192.168.0.0/24) y acceder al CCR2004 con Winbox o SSH.
- Mantener a mano el script `mikrotik-ccr2004-config.rsc` para comparar si es necesario.

## 2. Validacion del enlace ISP
1. Confirmar que la interfaz WAN esta levantada:
   ```routeros
   /interface ethernet print
   /interface print terse where name="ether1"
   ```
2. Revisar direccionamiento WAN:
   ```routeros
   /ip address print where interface="ether1"
   /ip route print where dst-address=0.0.0.0/0
   ```
3. Probar conectividad hacia el gateway y hacia Internet:
   ```routeros
   /ping 181.10.31.113
   /ping 1.1.1.1
   ```

## 3. DNS y resolucion de nombres
1. Verificar que la redireccion interna siga activa:
   ```routeros
   /ping virtual.itsv.edu.ar
   ```
2. Confirmar resolucion externa:
   ```routeros
   /ping itsv.edu.ar count=5
   /ping google.com count=5
   ```

## 4. Conectividad desde laboratorios
1. Desde cada segmento (ejemplo 192.168.0.2, .3, .5, .6, .70, .71, .100, .7, .8) ejecutar:
   ```bash
   ping 192.168.0.1
   ping 1.1.1.1
   ping google.com
   ```
2. En el router, revisar conexiones NAT activas:
   ```routeros
   /ip firewall connection print where src-address~"192.168.0."
   ```

## 5. Monitoreo de QoS
1. Abrir estadisticas de colas simples mientras se generan pruebas:
   ```routeros
   /queue simple print stats
   ```
2. Opcional: observar trafico por host o interfaz:
   ```routeros
   /tool torch bridge-lan
   /interface monitor-traffic bridge-lan
   ```

## 6. Prueba de esfuerzo controlada
- Ejecutar descargas o streaming simultaneo desde varios laboratorios y confirmar que las colas respetan `limit-at` y `max-limit`.
- Si se dispone de un host de prueba, usar:
  ```routeros
  /tool bandwidth-test address=192.168.0.X user=test password=test duration=30s protocol=tcp direction=both
  ```
  (limitar el ancho de banda para no saturar el enlace real).

## 7. Revisiones finales
- Consultar los registros en busca de warnings o errores:
  ```routeros
  /log print where topics~"error|warning"
  ```
- Revisar estado general del sistema:
  ```routeros
  /system resource print
  /system clock print
  ```
- Guardar respaldo de la configuracion si todo fue satisfactorio:
  ```routeros
  /system backup save name=post-migracion
  /export file=post-migracion
  ```
