/ip address add address=192.168.0.2/24 interface=ether1
/ip route add dst-address=0.0.0.0/0 gateway=192.168.0.1

/interface bridge add name=bridge
/interface bridge port add bridge=bridge interface=ether2
/interface bridge port add bridge=bridge interface=ether3
/interface bridge port add bridge=bridge interface=ether4
/interface bridge port add bridge=bridge interface=ether5


/ip address add address=192.168.20.1/24 interface=bridge

/ip pool add name=dhcp_pool ranges=192.168.20.170-192.168.20.220
/ip dhcp-server add name=dhcp1 interface=bridge address-pool=dhcp_pool lease-time=10m disabled=no
/ip dhcp-server network add address=192.168.20.0/24 gateway=192.168.20.1 dns-server=8.8.8.8,8.8.4.4 domain=ServProyecto

/ip dns set servers=8.8.8.8,8.8.4.4 allow-remote-requests=yes

/ip firewall nat add chain=srcnat out-interface=ether1 action=masquerade
