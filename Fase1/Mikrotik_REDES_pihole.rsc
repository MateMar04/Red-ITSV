/ip address
add address=192.168.0.2/24 interface=ether1
add address=192.168.20.1/24 interface=bridge

/ip route
add dst-address=0.0.0.0/0 gateway=192.168.0.1

/interface bridge
add name=bridge

/interface bridge port
add bridge=bridge interface=ether2
add bridge=bridge interface=ether3
add bridge=bridge interface=ether4
add bridge=bridge interface=ether5

/ip pool
add name=dhcp_pool ranges=192.168.20.170-192.168.20.220

/ip dhcp-server
add name=dhcp1 interface=bridge address-pool=dhcp_pool lease-time=10m disabled=no

/ip dhcp-server network
add address=192.168.20.0/24 gateway=192.168.20.1 dns-server=192.168.20.2 domain=ServProyecto

/ip dns
set servers=1.1.1.1,8.8.8.8 allow-remote-requests=yes

/ip firewall nat
add chain=srcnat out-interface=ether1 action=masquerade

# Excepción: el propio Pi-hole no debe ser redirigido
add chain=dstnat src-address=192.168.20.2 protocol=udp dst-port=53 action=accept
add chain=dstnat src-address=192.168.20.2 protocol=tcp dst-port=53 action=accept

# Forzar todo el DNS de la LAN hacia Pi-hole
add chain=dstnat in-interface=bridge src-address=192.168.20.0/24 dst-address=!192.168.20.2 protocol=udp dst-port=53 action=dst-nat to-addresses=192.168.20.2
add chain=dstnat in-interface=bridge src-address=192.168.20.0/24 dst-address=!192.168.20.2 protocol=tcp dst-port=53 action=dst-nat to-addresses=192.168.20.2