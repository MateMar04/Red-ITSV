# === Firewall DNS Blacklist - ITS Villada ===
# Configuración para MikroTik CCR2004 - RouterOS 7
# Ejecutar UNA VEZ para configurar el sistema de bloqueo y actualización.
#
# ESTRATEGIA:
# 1. Usar CleanBrowsing DNS (filtro familia) como upstream → bloquea
#    automáticamente millones de dominios adult/porn sin cargar el router.
# 2. Blacklist local via DNS estático → bloquea categorías adicionales
#    (gambling, games, dating, social_networks, hacking, etc.)
# 3. Forzar todo DNS por el MikroTik → evitar bypass.
#
# Esto combina lo mejor de ambos mundos: el filtrado pesado lo hace
# el DNS externo, y las categorías específicas del colegio las maneja
# el MikroTik localmente.

# -------------------------------------------------------
# 1. DNS con filtrado - CleanBrowsing Family Filter
#    Bloquea: adult, porn, proxies, VPNs, mixed adult content
#    Es gratuito y no requiere cuenta.
#    Alternativas: OpenDNS FamilyShield (208.67.222.123, 208.67.220.123)
# -------------------------------------------------------
/ip dns set \
    servers=185.228.168.168,185.228.169.168 \
    allow-remote-requests=yes \
    cache-size=4096KiB

# Mantener la entrada DNS estática existente para virtual.itsv.edu.ar
# (ya configurada en el config principal)

# -------------------------------------------------------
# 2. Forzar TODO el tráfico DNS a pasar por el MikroTik
#    Esto evita que los dispositivos usen DNS externos (bypass).
# -------------------------------------------------------
/ip firewall nat
add chain=dstnat protocol=udp dst-port=53 in-interface-list=LAN \
    dst-address=!192.168.0.1 action=redirect to-ports=53 \
    comment="Forzar DNS UDP al MikroTik (anti-bypass)"
add chain=dstnat protocol=tcp dst-port=53 in-interface-list=LAN \
    dst-address=!192.168.0.1 action=redirect to-ports=53 \
    comment="Forzar DNS TCP al MikroTik (anti-bypass)"

# -------------------------------------------------------
# 3. Bloquear métodos de bypass de DNS
# -------------------------------------------------------

# Bloquear DNS over TLS (DoT - puerto 853)
/ip firewall filter
add chain=forward protocol=tcp dst-port=853 action=drop \
    comment="Bloquear DNS over TLS (DoT) - anti-bypass"
move [find comment="Bloquear DNS over TLS (DoT) - anti-bypass"] \
     [find comment="LAN a WAN"]

# Bloquear DNS over HTTPS (DoH) a proveedores conocidos
/ip firewall address-list
add list=doh-servers address=1.0.0.1           comment="Cloudflare DoH"
add list=doh-servers address=1.1.1.1           comment="Cloudflare DoH"
add list=doh-servers address=8.8.4.4           comment="Google DoH"
add list=doh-servers address=8.8.8.8           comment="Google DoH"
add list=doh-servers address=9.9.9.9           comment="Quad9 DoH"
add list=doh-servers address=149.112.112.112   comment="Quad9 DoH"
add list=doh-servers address=208.67.220.220    comment="OpenDNS DoH"
add list=doh-servers address=208.67.222.222    comment="OpenDNS DoH"
add list=doh-servers address=76.76.2.0         comment="ControlD DoH"
add list=doh-servers address=76.76.10.0        comment="ControlD DoH"
add list=doh-servers address=94.140.14.14      comment="AdGuard DoH"
add list=doh-servers address=94.140.15.15      comment="AdGuard DoH"

/ip firewall filter
add chain=forward protocol=tcp dst-port=443 \
    dst-address-list=doh-servers action=drop \
    comment="Bloquear DoH a proveedores conocidos - anti-bypass"
move [find comment="Bloquear DoH a proveedores conocidos - anti-bypass"] \
     [find comment="LAN a WAN"]

# -------------------------------------------------------
# 4. Script de actualización automática de blacklists
# -------------------------------------------------------
# CONFIGURAR: Cambie la URL al servidor donde corre generate-blacklist.py
# Ejemplo: python3 generate-blacklist.py --serve 8080
#          en el equipo 192.168.0.X de la LAN del colegio.

/system script
add name="update-blacklist" policy=read,write,test source={
:local url "http://192.168.0.100:8080/blacklist-dns.rsc"
:local filename "blacklist-dns.rsc"

:log info "Blacklist: Iniciando actualizacion..."

:do {
    /tool fetch url=$url dst-path=$filename mode=http
    :delay 2s

    :local fileSize [/file get $filename size]
    :if ($fileSize < 1024) do={
        :log error "Blacklist: Archivo descargado muy pequeno, abortando."
        /file remove $filename
        :error "Archivo invalido"
    }

    :log info "Blacklist: Descarga OK ($fileSize bytes). Importando..."
    /import file-name=$filename
    :delay 1s
    /file remove $filename
    :log info "Blacklist: Actualizacion completa."
} on-error={
    :log error "Blacklist: Error al descargar o importar la lista."
}
}

# -------------------------------------------------------
# 5. Scheduler - Actualizar cada día a las 4:00 AM
# -------------------------------------------------------
/system scheduler
add name="blacklist-update" interval=1d start-time=04:00:00 \
    on-event="update-blacklist" \
    policy=read,write,test \
    comment="Actualizar blacklist DNS diariamente"

# -------------------------------------------------------
# 6. (Opcional) Logging de consultas DNS bloqueadas
# -------------------------------------------------------
# Para ver en el log qué dominios se están bloqueando:
# /system logging add topics=dns,debug action=memory
# NOTA: Esto genera MUCHO log, usar solo para diagnóstico temporal.

# -------------------------------------------------------
# 7. Ejecutar primera actualización
# -------------------------------------------------------
# Después de configurar la URL correcta, ejecutar manualmente:
# /system script run update-blacklist
