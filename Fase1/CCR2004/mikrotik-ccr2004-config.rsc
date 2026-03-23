# === Migracion ZeroShell -> MikroTik CCR2004 ===
# Ejecute despues de un reset sin la configuracion por defecto (/system reset-configuration no-defaults=yes).
# Revise cada seccion y adapte nombres de interfaces fisicas segun su cableado.

/system identity set name="panca.itsv.edu.ar"
/system clock set time-zone-name=Europe/Rome
/system ntp client set enabled=yes mode=unicast server-dns-names=0.pool.ntp.org,1.pool.ntp.org,2.pool.ntp.org,3.pool.ntp.org

/interface bridge
add name=bridge-lan comment="LAN principal (ZeroShell ETH01)" protocol-mode=rstp
add name=loopback-ovpn comment="Loopback OpenVPN (ZeroShell VPN99)" protocol-mode=none

/interface bridge port
add bridge=bridge-lan interface=ether2 comment="LAN uplink (ajuste segun puertos usados)"

/interface list
add name=WAN comment="Enlace saliente (ZeroShell ETH00)"
add name=LAN comment="Redes internas (LAN + VPN)"

/interface list member
add interface=ether1 list=WAN comment="ISP - 181.10.31.114/29"
add interface=bridge-lan list=LAN
add interface=loopback-ovpn list=LAN

/ip address
add address=181.10.31.114/29 interface=ether1 comment="WAN - ZeroShell ETH00"
add address=192.168.0.1/24 interface=bridge-lan comment="LAN - ZeroShell ETH01"
add address=192.168.250.254/24 interface=loopback-ovpn comment="Gateway VPN - ZeroShell VPN99"

/ip route
add dst-address=0.0.0.0/0 gateway=181.10.31.113 distance=1 comment="Default route - ZeroShell"

/ip dns
set allow-remote-requests=yes cache-size=4096KiB servers=1.1.1.1
/ip dns static
add name="virtual.itsv.edu.ar" type=FWD forward-to=192.168.0.70 match-subdomain=yes ttl=1d comment="Redireccion especifica como en ZeroShell"

/ip firewall address-list
add list=internal-networks address=192.168.0.0/24 comment="LAN"
add list=internal-networks address=192.168.250.0/24 comment="Clientes OpenVPN"

/ip firewall nat
add chain=srcnat action=masquerade out-interface-list=WAN src-address-list=internal-networks comment="NAT interno hacia WAN"

/ip firewall filter
add chain=input action=accept connection-state=established,related comment="Entrada established/related"
add chain=input action=drop connection-state=invalid comment="Entrada invalid"
add chain=input action=accept in-interface-list=LAN comment="Gestion desde redes internas"
add chain=input action=accept in-interface-list=WAN protocol=tcp dst-port=1194 comment="OpenVPN TCP 1194 (servidor inicialmente deshabilitado)"
add chain=input action=drop in-interface-list=WAN comment="Bloqueo de acceso directo desde WAN"
add chain=forward action=accept connection-state=established,related comment="Forward established/related"
add chain=forward action=drop connection-state=invalid comment="Forward invalid"
add chain=forward action=accept in-interface-list=LAN out-interface-list=WAN comment="LAN a WAN"
add chain=forward action=accept src-address-list=internal-networks out-interface-list=WAN comment="VPN a WAN"
add chain=forward action=drop in-interface-list=WAN connection-state=new comment="Bloqueo conexiones entrantes no solicitadas"

/ip service
set [find name=telnet] disabled=yes
set [find name=ftp] disabled=yes
set [find name=www] disabled=yes
set [find name=www-ssl] disabled=yes
set [find name=api] disabled=yes
set [find name=api-ssl] disabled=yes
set [find name=ssh] port=22 strong-crypto=yes
set [find name=winbox] address=192.168.0.0/24,192.168.250.0/24

/system note
set show-at-login=yes note="CCR2004 migrada desde ZeroShell. Revisar usuarios VPN y certificados antes de habilitar servicios."

/ip pool
add name=ovpn-pool ranges=192.168.250.1-192.168.250.253

/ppp profile
add name=ovpn-profile local-address=192.168.250.254 remote-address=ovpn-pool dns-server=192.168.250.254 use-encryption=required comment="Perfil OpenVPN equivalente a ZeroShell"

/interface ovpn-server server
set enabled=no port=1194 mode=ip netmask=24 protocol=tcp default-profile=ovpn-profile auth=sha1 cipher=aes256 require-client-certificate=yes keepalive-timeout=60

# Cree usuarios VPN con /ppp secret add name="usuario" password="clave" profile=ovpn-profile service=ovpn
# Importe los certificados desde Database/etc/ssl si desea habilitar OpenVPN con verificacion X.509.

/system logging
set 0 topics=info
set 1 topics=error
set 2 topics=warning
add topics=firewall

/tool mac-server mac-winbox
set allowed-interface-list=LAN
/tool mac-server
set allowed-interface-list=none

# Ajuste /interface bridge port para anadir mas puertos LAN (ether3-ether16, sfp-sfpplus1/2) si aplica.
# Revise tambien los scripts maliciosos detectados en el backup antes de automatizar tareas en el nuevo router.
