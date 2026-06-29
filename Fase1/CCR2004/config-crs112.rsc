
/interface bridge add name=bridge-lan protocol-mode=rstp

/port set 0 name=serial0

/interface bridge port
add bridge=bridge-lan comment="Uplink CCR2004 - trunk LAN sin etiqueta + VLAN 50 tagged" interface=ether1 hw=yes
add bridge=bridge-lan comment="LAN gestion sin etiqueta" interface=ether2 hw=yes
add bridge=bridge-lan comment="Trunk AP/switch RED-ITSV - LAN sin etiqueta + VLAN 50 tagged" interface=ether3 hw=yes
add bridge=bridge-lan comment="LAN gestion sin etiqueta" interface=ether4 hw=yes

# VLAN 50 RED-ITSV/WiFi en switch-chip CRS1xx.
# VLAN 0 mantiene la gestion 192.168.0.0/24 sin etiqueta hacia la CPU.
# VLAN 50 se transporta solo por el uplink ether1 y el puerto ether3.
/interface ethernet switch vlan
add ports=switch1-cpu,ether1,ether2,ether3,ether4 vlan-id=0
add ports=ether1,ether3 vlan-id=50
/interface ethernet switch egress-vlan-tag
add tagged-ports=ether1,ether3 vlan-id=50
/interface ethernet switch
set drop-if-invalid-or-src-port-not-member-of-vlan-on-ports=ether1,ether2,ether3,ether4

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
