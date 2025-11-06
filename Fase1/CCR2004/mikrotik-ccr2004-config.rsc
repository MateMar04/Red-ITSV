# === Migracion ZeroShell -> MikroTik CCR2004 ===
# Ejecute despues de un reset sin la configuracion por defecto (/system reset-configuration no-defaults=yes).
# Revise cada seccion y adapte nombres de interfaces fisicas segun su cableado.

/system identity set name="panca.itsv.edu.ar"
/system clock set time-zone-name=America/Buenos_Aires
/system ntp client set enabled=yes mode=unicast

/interface bridge add name=bridge-lan comment="LAN Principal" protocol-mode=rstp

/interface bridge port add bridge=bridge-lan interface=ether2
/interface bridge port add bridge=bridge-lan interface=ether3
/interface bridge port add bridge=bridge-lan interface=ether4
/interface bridge port add bridge=bridge-lan interface=ether5
/interface bridge port add bridge=bridge-lan interface=ether6
/interface bridge port add bridge=bridge-lan interface=ether7
/interface bridge port add bridge=bridge-lan interface=ether8
/interface bridge port add bridge=bridge-lan interface=ether9
/interface bridge port add bridge=bridge-lan interface=ether10
/interface bridge port add bridge=bridge-lan interface=ether11
/interface bridge port add bridge=bridge-lan interface=ether12

/interface list add name=WAN comment="Enlace saliente"
/interface list add name=LAN comment="Redes internas"

/interface list member add interface=ether1 list=WAN comment="ISP - 181.10.31.114/29"
/interface list member add interface=bridge-lan list=LAN

/ip address add address=181.10.31.114/29 interface=ether1 comment="WAN"
/ip address add address=192.168.0.1/24 interface=bridge-lan comment="LAN"

/ip route add dst-address=0.0.0.0/0 gateway=181.10.31.113 distance=1 comment="Default route"

/ip dns set allow-remote-requests=yes cache-size=4096KiB servers=1.1.1.1
/ip dns static add name="virtual.itsv.edu.ar" type=FWD forward-to=192.168.0.70 match-subdomain=yes ttl=1d comment="Redireccion especifica como en ZeroShell"

/ip firewall address-list add list=internal-networks address=192.168.0.0/24 comment="LAN"

/ip firewall nat add chain=srcnat action=masquerade out-interface-list=WAN src-address-list=internal-networks comment="NAT interno hacia WAN"

/ip firewall filter add chain=input action=accept connection-state=established,related comment="Entrada established/related"
/ip firewall filter add chain=input action=drop connection-state=invalid comment="Entrada invalid"
/ip firewall filter add chain=input action=accept in-interface-list=LAN comment="Gestion desde redes internas"
/ip firewall filter add chain=input action=drop in-interface-list=WAN comment="Bloqueo de acceso directo desde WAN"
/ip firewall filter add chain=forward action=accept connection-state=established,related comment="Forward established/related"
/ip firewall filter add chain=forward action=drop connection-state=invalid comment="Forward invalid"
/ip firewall filter add chain=forward action=accept in-interface-list=LAN out-interface-list=WAN comment="LAN a WAN"
/ip firewall filter add chain=forward action=drop in-interface-list=WAN connection-state=new comment="Bloqueo conexiones entrantes no solicitadas"

# === QoS replicado de ZeroShell ===
/queue simple add name=QoS_TOTAL target=192.168.0.0/24 limit-at=200M/200M max-limit=1000M/1000M priority=1/1 queue=default/default comment="ETH01"
/queue simple add name=QoS_RED4 parent=QoS_TOTAL target=192.168.0.4/32 limit-at=50M/50M max-limit=80M/80M priority=1/1 queue=default/default comment="Host 192.168.0.4 (Clase RED4)"
/queue simple add name=QoS_ADMIN parent=QoS_TOTAL target=192.168.0.8/32 limit-at=50M/50M max-limit=90M/90M priority=1/1 queue=default/default comment="Administracion (Clase ADMIN)"
/queue simple add name=QoS_LABREDES parent=QoS_TOTAL target=192.168.0.2/32 limit-at=100M/100M max-limit=150M/150M priority=2/2 queue=default/default comment="Laboratorio de Redes (Clase LABREDES)"
/queue simple add name=QoS_LABPROG1 parent=QoS_TOTAL target=192.168.0.5/32 limit-at=80M/80M max-limit=150M/150M priority=2/2 queue=default/default comment="Laboratorio Prog 1 (Clase LABPROG1)"
/queue simple add name=QoS_LABPROG2 parent=QoS_TOTAL target=192.168.0.6/32 limit-at=100M/100M max-limit=150M/150M priority=1/1 queue=default/default comment="Laboratorio Prog 2 (Clase LABPROG2)"
/queue simple add name=QoS_LABPROG3 parent=QoS_TOTAL target=192.168.0.70/32 limit-at=50M/50M max-limit=80M/80M priority=2/2 queue=default/default comment="Laboratorio Prog 3 (Clase LABPROG3)"
/queue simple add name=QoS_LABPROY parent=QoS_TOTAL target=192.168.0.3/32 limit-at=100M/100M max-limit=200M/200M priority=2/2 queue=default/default comment="Laboratorio Proyectos (Clase LABPROY)"
/queue simple add name=QoS_LABSELECTR parent=QoS_TOTAL target=192.168.0.71/32 limit-at=50M/50M max-limit=100M/100M priority=2/2 queue=default/default comment="Laboratorio Electronica (Clase LABSELECTR)"
/queue simple add name=QoS_LABSEM parent=QoS_TOTAL target=192.168.0.100/32 limit-at=50M/50M max-limit=80M/80M priority=3/3 queue=default/default comment="Laboratorio Electromecanica (Clase LABSEM)"
/queue simple add name=QoS_WIFI parent=QoS_TOTAL target=192.168.0.7/32 limit-at=20M/20M max-limit=20M/20M priority=3/3 queue=default/default comment="Wifi Mikrotik (Clase WIFI)"
/queue simple add name=QoS_DEFAULT parent=QoS_TOTAL target=192.168.0.0/24 limit-at=20M/20M max-limit=20M/20M priority=3/3 queue=default/default comment="Trafico no clasificado (Clase DEFAULT)"

/ip service set [find name=telnet] disabled=yes
/ip service set [find name=ftp] disabled=yes
/ip service set [find name=www] disabled=yes
/ip service set [find name=www-ssl] disabled=yes
/ip service set [find name=api] disabled=yes
/ip service set [find name=api-ssl] disabled=yes
/ip service set [find name=winbox] address=192.168.0.0/24

/system note set show-at-login=yes note="CCR2004-16G-2S+"
