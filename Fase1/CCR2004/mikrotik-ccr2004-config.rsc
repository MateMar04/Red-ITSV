# Revise cada seccion y adapte nombres de interfaces fisicas segun su cableado.
# Ajuste SSID, password WiFi y limites QoS antes de aplicar CAPsMAN.

/system identity set name="panca.itsv.edu.ar"

/system clock set time-zone-name=America/Buenos_Aires
/system ntp client set enabled=yes mode=unicast

/interface bridge add name=bridge-lan comment="LAN Principal" protocol-mode=rstp pvid=1 vlan-filtering=no

/interface bridge port add bridge=bridge-lan interface=ether2 pvid=1 ingress-filtering=yes frame-types=admit-all
/interface bridge port add bridge=bridge-lan interface=ether3 pvid=1 ingress-filtering=yes frame-types=admit-all
/interface bridge port add bridge=bridge-lan interface=ether4 pvid=1 ingress-filtering=yes frame-types=admit-all
/interface bridge port add bridge=bridge-lan interface=ether5 pvid=1 ingress-filtering=yes frame-types=admit-all
/interface bridge port add bridge=bridge-lan interface=ether6 pvid=1 ingress-filtering=yes frame-types=admit-all
/interface bridge port add bridge=bridge-lan interface=ether7 pvid=1 ingress-filtering=yes frame-types=admit-all
/interface bridge port add bridge=bridge-lan interface=ether8 pvid=1 ingress-filtering=yes frame-types=admit-all
/interface bridge port add bridge=bridge-lan interface=ether9 pvid=1 ingress-filtering=yes frame-types=admit-all
/interface bridge port add bridge=bridge-lan interface=ether10 comment="Trunk CRS112 - LAN sin etiqueta + VLAN 50 tagged" pvid=1 ingress-filtering=yes frame-types=admit-all
/interface bridge port add bridge=bridge-lan interface=ether11 pvid=1 ingress-filtering=yes frame-types=admit-all
/interface bridge port add bridge=bridge-lan interface=ether12 pvid=1 ingress-filtering=yes frame-types=admit-all

# VLAN 50 RED-ITSV/WiFi.
# Ajustar "ether10" si el uplink al CRS112 esta conectado a otro puerto del CCR2004.
# Agregar otros puertos a tagged si tambien llevan switches/APs con VLAN 50.
/interface bridge vlan add bridge=bridge-lan vlan-ids=1 untagged=bridge-lan,ether2,ether3,ether4,ether5,ether6,ether7,ether8,ether9,ether10,ether11,ether12 comment="LAN gestion sin etiqueta"
/interface bridge vlan add bridge=bridge-lan vlan-ids=50 tagged=bridge-lan,ether10 comment="VLAN 50 RED-ITSV/WiFi tagged hacia CRS112"

/interface list add name=WAN comment="Enlace saliente"
/interface list add name=LAN comment="Redes internas"

/interface list member add interface=ether1 list=WAN comment="ISP - 181.10.31.114/29"
/interface list member add interface=bridge-lan list=LAN

/ip address add address=181.10.31.114/29 interface=ether1 comment="WAN"
/ip address add address=192.168.0.1/24 interface=bridge-lan comment="LAN"

# === Red WiFi separada para CAPsMAN / captive-ready ===
/interface vlan add interface=bridge-lan name=vlan-wifi vlan-id=50 comment="WiFi separado CAPsMAN - VLAN 50"
/ip address add address=10.50.0.1/24 interface=vlan-wifi comment="Gateway WiFi CAPsMAN"

/ip pool add name=pool-wifi ranges=10.50.0.50-10.50.0.250
/ip dhcp-server add name=dhcp-wifi interface=vlan-wifi address-pool=pool-wifi lease-time=4h disabled=no
/ip dhcp-server network add address=10.50.0.0/24 gateway=10.50.0.1 dns-server=10.50.0.1 domain=wifi.itsv.edu.ar comment="DHCP WiFi CAPsMAN"

/interface bridge set [find name=bridge-lan] vlan-filtering=yes

/ip route add dst-address=0.0.0.0/0 gateway=181.10.31.113 distance=1 comment="Default route"

/ip dns set allow-remote-requests=yes cache-size=4096KiB servers=1.1.1.1
/ip dns static add name="virtual.itsv.edu.ar" type=FWD forward-to=192.168.0.70 match-subdomain=yes ttl=1d comment="Redireccion especifica como en ZeroShell"

/ip firewall address-list add list=internal-networks address=192.168.0.0/24 comment="LAN"
/ip firewall address-list add list=internal-networks address=10.50.0.0/24 comment="WiFi CAPsMAN"
/ip firewall address-list add list=private-networks address=10.0.0.0/8 comment="RFC1918"
/ip firewall address-list add list=private-networks address=172.16.0.0/12 comment="RFC1918"
/ip firewall address-list add list=private-networks address=192.168.0.0/16 comment="RFC1918"

/ip firewall nat add chain=srcnat action=masquerade out-interface-list=WAN src-address-list=internal-networks comment="NAT interno hacia WAN"

/ip firewall filter add chain=input action=accept connection-state=established,related comment="Entrada established/related"
/ip firewall filter add chain=input action=drop connection-state=invalid comment="Entrada invalid"
/ip firewall filter add chain=input action=accept in-interface-list=LAN comment="Gestion desde redes internas"
/ip firewall filter add chain=input action=drop in-interface-list=WAN comment="Bloqueo de acceso directo desde WAN"
/ip firewall filter add chain=forward action=accept connection-state=established,related comment="Forward established/related"
/ip firewall filter add chain=forward action=drop connection-state=invalid comment="Forward invalid"
/ip firewall filter add chain=forward action=accept in-interface-list=LAN out-interface-list=WAN comment="LAN a WAN"
/ip firewall filter add chain=forward action=drop in-interface-list=WAN connection-state=new comment="Bloqueo conexiones entrantes no solicitadas"
/ip firewall filter add chain=input action=accept in-interface=vlan-wifi protocol=udp dst-port=53,67,123 comment="WiFi CAPsMAN permite DNS/DHCP/NTP UDP"
/ip firewall filter add chain=input action=accept in-interface=vlan-wifi protocol=tcp dst-port=53 comment="WiFi CAPsMAN permite DNS TCP"
/ip firewall filter add chain=input action=drop in-interface=vlan-wifi comment="Bloqueo gestion del CCR2004 desde WiFi CAPsMAN"
/ip firewall filter add chain=forward action=drop in-interface=vlan-wifi dst-address-list=private-networks comment="Bloqueo WiFi CAPsMAN hacia redes privadas"
/ip firewall filter add chain=forward action=accept in-interface=vlan-wifi out-interface-list=WAN comment="WiFi CAPsMAN hacia Internet"

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

# === QoS WiFi CAPsMAN ===
/queue type add name=pcq-wifi-upload kind=pcq pcq-classifier=src-address pcq-rate=2M comment="WiFi CAPsMAN subida por cliente"
/queue type add name=pcq-wifi-download kind=pcq pcq-classifier=dst-address pcq-rate=5M comment="WiFi CAPsMAN bajada por cliente"
/queue simple add name=QoS_WIFI_CAPSMAN target=10.50.0.0/24 max-limit=80M/80M queue=pcq-wifi-upload/pcq-wifi-download comment="WiFi CAPsMAN total 80M con reparto por cliente"

# === CAPsMAN WiFi 6 ===
/interface wifi channel add name=ch-wifi-2g band=2ghz-ax width=20mhz skip-dfs-channels=all comment="2.4 GHz estable para alta densidad"
/interface wifi channel add name=ch-wifi-5g band=5ghz-ax width=20/40/80mhz skip-dfs-channels=all comment="5 GHz sin DFS para evitar cortes por radar"

/interface wifi datapath add name=dp-wifi bridge=bridge-lan vlan-id=50 client-isolation=yes comment="Datapath VLAN 50 para WiFi CAPsMAN"

/interface wifi security add name=sec-wifi authentication-types=wpa2-psk,wpa3-psk passphrase="CAMBIARME-WIFI-2026" ft=yes ft-over-ds=yes wps=disable comment="WPA2/WPA3 + 802.11r para roaming"

/interface wifi configuration add name=cfg-wifi-2g mode=ap ssid="ITSV-WIFI" country=Argentina channel=ch-wifi-2g security=sec-wifi datapath=dp-wifi comment="SSID WiFi 2.4 GHz"
/interface wifi configuration add name=cfg-wifi-5g mode=ap ssid="ITSV-WIFI" country=Argentina channel=ch-wifi-5g security=sec-wifi datapath=dp-wifi comment="SSID WiFi 5 GHz"

/interface wifi provisioning add action=create-dynamic-enabled supported-bands=2ghz-ax master-configuration=cfg-wifi-2g comment="Provisioning CAPs 2.4 GHz"
/interface wifi provisioning add action=create-dynamic-enabled supported-bands=5ghz-ax master-configuration=cfg-wifi-5g comment="Provisioning CAPs 5 GHz"

/interface wifi capsman set enabled=yes interfaces=bridge-lan ca-certificate=auto require-peer-certificate=no

# Futuro captive portal:
# - La red ya queda separada en vlan-wifi
# - Crear HotSpot sobre vlan-wifi, no sobre bridge-lan.
# - Antes de activar captive, revisar DNS, certificados HTTPS y walled garden.

# === VPN WireGuard para administracion remota ===
/interface wireguard add listen-port=13231 name=wg-admin comment="VPN Admin remota"
/ip address add address=10.10.10.1/24 interface=wg-admin comment="VPN Admin"

# Agregar peer (reemplazar PublicKey con la clave publica del cliente)
# Para generar claves en el cliente: wg genkey | tee privatekey | wg pubkey > publickey
/interface wireguard peers add interface=wg-admin \
    public-key="FQZvTz/YO3mmgXLeH8hwmCwLhxdeOY5qVhhdHRHTHww=" \
    allowed-address=10.10.10.2/32 \
    comment="Admin remoto - Mateo"

# Agregar interfaz VPN a la lista LAN para acceso a gestion
/interface list member add interface=wg-admin list=LAN comment="VPN Admin"

# Permitir trafico WireGuard entrante desde WAN
/ip firewall filter add chain=input action=accept protocol=udp dst-port=13231 in-interface-list=WAN \
    comment="Permitir WireGuard VPN" place-before=[find where comment="Bloqueo de acceso directo desde WAN"]

# === VPN WireGuard para alumnos - gestion limitada de Ubuntu ===
# Esta VPN no se agrega a interface-list=LAN para evitar gestion del CCR2004.
# Los alumnos solo pueden acceder por SSH al servidor Ubuntu 192.168.0.100.
/interface wireguard add listen-port=13232 name=wg-alumnos comment="VPN alumnos - acceso SSH Ubuntu"
/ip address add address=10.10.20.1/24 interface=wg-alumnos comment="VPN alumnos"

# Agregar peers cuando cada alumno entregue su clave publica.
# Ejemplo alumno 1:
# /interface wireguard peers add interface=wg-alumnos public-key="<PUBLIC_KEY_ALUMNO_1>" allowed-address=10.10.20.2/32 comment="Alumno 1 - SSH Ubuntu"
# Ejemplo alumno 2:
# /interface wireguard peers add interface=wg-alumnos public-key="<PUBLIC_KEY_ALUMNO_2>" allowed-address=10.10.20.3/32 comment="Alumno 2 - SSH Ubuntu"

# Permitir trafico WireGuard de alumnos desde WAN.
/ip firewall filter add chain=input action=accept protocol=udp dst-port=13232 in-interface-list=WAN \
    comment="Permitir WireGuard alumnos" place-before=[find where comment="Bloqueo de acceso directo desde WAN"]

# Bloquear gestion del CCR2004 desde la VPN de alumnos, permitiendo solo diagnostico ICMP.
/ip firewall filter add chain=input action=accept in-interface=wg-alumnos protocol=icmp comment="VPN alumnos permite ping al CCR2004"
/ip firewall filter add chain=input action=drop in-interface=wg-alumnos comment="VPN alumnos bloquea gestion del CCR2004"

# Permisos de la VPN de alumnos hacia la LAN: solo SSH al servidor Ubuntu.
/ip firewall filter add chain=forward action=accept in-interface=wg-alumnos dst-address=192.168.0.100 protocol=tcp dst-port=22 comment="VPN alumnos permite SSH a Ubuntu"
/ip firewall filter add chain=forward action=drop in-interface=wg-alumnos comment="VPN alumnos bloquea otros destinos"

/ip service set [find name=telnet] disabled=yes
/ip service set [find name=ftp] disabled=yes
/ip service set [find name=www] disabled=yes
/ip service set [find name=www-ssl] disabled=yes
/ip service set [find name=api] disabled=yes
/ip service set [find name=api-ssl] disabled=yes
/ip service set [find name=winbox] address=192.168.0.0/24,10.10.10.0/24

/system note set show-at-login=yes note="CCR2004-16G-2S+"
