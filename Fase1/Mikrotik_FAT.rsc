/ip address add address=192.168.0.3/24 interface=ether1
/ip route add dst-address=0.0.0.0/0 gateway=192.168.0.1

/interface bridge add name=bridge
/interface bridge port add bridge=bridge interface=ether2
/interface bridge port add bridge=bridge interface=ether3
/interface bridge port add bridge=bridge interface=ether4
/interface bridge port add bridge=bridge interface=ether5

/interface wireless security-profiles add name=lan-wifi
/interface wireless security-profiles set [find name=lan-wifi] mode=dynamic-keys authentication-types=wpa2-psk wpa2-pre-shared-key="CAMBIARME2025!" supplicant-identity="MikroTik RD53"
/interface wireless set [find default-name=wlan1] mode=ap-bridge ssid="PROGRAMACION-FAT" band=2ghz-onlyn channel-width=20/40mhz-XX frequency=auto country=argentina security-profile=lan-wifi max-station-count=30 installation=indoor disabled=no
/interface wireless set [find default-name=wlan2] mode=ap-bridge ssid="PROGRAMACION-FAT-5G" band=5ghz-onlyac channel-width=20/40/80mhz-Ceee frequency=auto country=argentina security-profile=lan-wifi max-station-count=30 installation=indoor disabled=no
/interface bridge port add bridge=bridge interface=wlan1
/interface bridge port add bridge=bridge interface=wlan2

/ip address add address=192.168.30.1/24 interface=bridge

/ip pool add name=dhcp_pool ranges=192.168.30.170-192.168.30.220
/ip dhcp-server add name=dhcp1 interface=bridge address-pool=dhcp_pool lease-time=10m disabled=no
/ip dhcp-server network add address=192.168.30.0/24 gateway=192.168.30.1 dns-server=8.8.8.8,8.8.4.4 domain=ServProyecto

/ip dns set servers=8.8.8.8,8.8.4.4 allow-remote-requests=yes

/ip firewall nat add chain=srcnat out-interface=ether1 action=masquerade
