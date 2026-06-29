
/interface bridge add name=bridge-lan

/port set 0 name=serial0

/interface bridge port
add bridge=bridge-lan comment="Uplink CCR2004" interface=ether1
add bridge=bridge-lan interface=ether2
add bridge=bridge-lan interface=ether3
add bridge=bridge-lan interface=ether4

/ip address
add address=192.168.0.12/24 interface=bridge-lan network=192.168.0.0

/ip dns
set servers=8.8.8.8,1.1.1.1

/ip route
add gateway=192.168.0.1

/system clock
set time-zone-name=America/Argentina/Cordoba

/system note
set show-at-login=no

/system ntp client
set enabled=yes

/system routerboard settings
set enter-setup-on=delete-key
