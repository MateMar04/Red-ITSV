# Cliente CAP WiFi 6 para hAP ax3 / cAP ax
# Aplicar en cada AP despues de:
# /system reset-configuration no-defaults=yes skip-backup=yes
#
# Ajustar antes de importar:
# - identity: cap-ax-01, cap-ax-02, etc.
# - caps-man-addresses si el CCR2004 no usa 192.168.0.1.

/system identity set name="cap-ax-01"
/system clock set time-zone-name=America/Buenos_Aires

/interface bridge add name=bridgeLocal protocol-mode=rstp comment="Bridge local del CAP"

:foreach ethernetPort in=[/interface ethernet find] do={
    :local ethernetName [/interface ethernet get $ethernetPort name]
    /interface bridge port add bridge=bridgeLocal interface=$ethernetName comment="Puerto ethernet CAP"
}

/ip dhcp-client add interface=bridgeLocal disabled=no comment="IP de gestion del CAP desde LAN"

/interface wifi datapath add name=capdp bridge=bridgeLocal comment="Datapath local para interfaces controladas por CAPsMAN"

/interface wifi set [find default-name=wifi1] configuration.manager=capsman datapath=capdp disabled=no
/interface wifi set [find default-name=wifi2] configuration.manager=capsman datapath=capdp disabled=no

/interface wifi cap set enabled=yes discovery-interfaces=bridgeLocal caps-man-addresses=192.168.0.1 slaves-datapath=capdp lock-to-caps-man=yes
