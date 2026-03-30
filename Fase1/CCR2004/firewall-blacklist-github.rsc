# === Firewall DNS Blacklist (GitHub) - ITS Villada ===
# Configuracion para MikroTik CCR2004 - RouterOS 7
# Esta version descarga la blacklist directamente desde GitHub Releases.
# No requiere ningun servidor local.
#
# Ejecutar UNA VEZ para configurar el sistema.

# -------------------------------------------------------
# 1. DNS con filtrado - CleanBrowsing Family Filter
# -------------------------------------------------------
/ip dns set \
    servers=185.228.168.168,185.228.169.168 \
    allow-remote-requests=yes \
    cache-size=4096KiB

# -------------------------------------------------------
# 2. Forzar TODO el trafico DNS a pasar por el MikroTik
# -------------------------------------------------------
/ip firewall nat
add chain=dstnat protocol=udp dst-port=53 in-interface-list=LAN \
    dst-address=!192.168.0.1 action=redirect to-ports=53 \
    comment="Forzar DNS UDP al MikroTik (anti-bypass)"
add chain=dstnat protocol=tcp dst-port=53 in-interface-list=LAN \
    dst-address=!192.168.0.1 action=redirect to-ports=53 \
    comment="Forzar DNS TCP al MikroTik (anti-bypass)"

# -------------------------------------------------------
# 3. Bloquear metodos de bypass de DNS
# -------------------------------------------------------
/ip firewall filter
add chain=forward protocol=tcp dst-port=853 action=drop \
    comment="Bloquear DNS over TLS (DoT) - anti-bypass"
move [find comment="Bloquear DNS over TLS (DoT) - anti-bypass"] \
     [find comment="LAN a WAN"]

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
# 4. Script de actualizacion desde GitHub Releases
# -------------------------------------------------------
/system script
add name="update-blacklist" policy=read,write,test source={
:local ghUser "MateMar04"
:local ghRepo "Red-ITSV"
:local ghTag "latest-blacklist"
:local filename "blacklist-dns.rsc"
:local url "https://github.com/$ghUser/$ghRepo/releases/download/$ghTag/$filename"

:log info "Blacklist: Iniciando descarga desde GitHub..."

:do {
    /tool fetch url=$url dst-path=$filename mode=https check-certificate=no
    :delay 2s

    :local fileSize [/file get $filename size]
    :if ($fileSize < 1024) do={
        :log error "Blacklist: Archivo descargado muy pequeno, abortando."
        /file remove $filename
        :error "Archivo invalido"
    }

    :log info "Blacklist: Descarga OK. Importando..."
    /import file-name=$filename
    :delay 1s
    /file remove $filename
    :log info "Blacklist: Actualizacion completa."
} on-error={
    :log error "Blacklist: Error al descargar o importar desde GitHub."
}
}

# -------------------------------------------------------
# 5. Scheduler - Actualizar cada dia a las 4:00 AM
# -------------------------------------------------------
/system scheduler
add name="blacklist-update" interval=1d start-time=04:00:00 \
    on-event="update-blacklist" \
    policy=read,write,test \
    comment="Actualizar blacklist DNS diariamente desde GitHub"

# -------------------------------------------------------
# 6. Ejecutar primera actualizacion (descomentar para correr ahora)
# -------------------------------------------------------
# /system script run update-blacklist
