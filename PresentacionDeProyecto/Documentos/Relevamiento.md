## Situación Actual

En la actualidad, la red del colegio se encuentra centralizada en una PC conocida como **“Pan Casero”**, que cumple la función de servidor de red.  
Este equipo utiliza **Zeroshell**, una distribución Linux orientada a redes (router, firewall, servidor VPN y gestor de red avanzado).

- Lanzamiento: **2006**
- Última versión estable: **2017**
- Fin de vida (EOL): **2018**

Al estar desactualizada, esta herramienta representa un **riesgo en términos de seguridad y eficiencia**, lo que puede impactar en la estabilidad general de la red.

## Equipamiento Principal

- **Switch principal:** distribuye el tráfico hacia los distintos sectores del colegio (laboratorios de programación, electrónica, electromecánica, administración, dirección, etc.).
    - Velocidad máxima: **100 Mbps**
    - Limitante: todas las redes internas soportan hasta **1000 Mbps (1 Gbps)**, por lo que el switch restringe el rendimiento a un **10% de la capacidad máxima**.
    - El servicio actual de **Telecom Integra** brinda **200 Mbps**, suficiente para el presente, pero este cuello de botella impedirá escalar a mayores velocidades en el futuro.
    
- **Cableado estructurado:**
    - Laboratorios de programación: cableado con **CAT6** (hasta **1 Gbps a 100 m** y hasta **10 Gbps a 55 m**).
    - Otras áreas: parte del cableado es **CAT5e** (hasta **1 Gbps a 100 m**).
    - Problema detectado: el cable de entrada de Internet hacia _Pan Casero_ es **CAT5e**, generando un **cuello de botella en el primer eslabón de la red**.
    
- **Conectividad inalámbrica (WiFi):**
    - Hay sectores (ej. preceptorías de planta baja) donde **no llega cobertura**.
    - Los **access points existentes no soportan la densidad de dispositivos actuales**, lo que genera saturación.
    - Las computadoras modernas ya no incluyen puerto **RJ45 (Ethernet)**, por lo que se hace indispensable reforzar la **infraestructura WiFi**.
    
- **Laboratorios y secciones técnicas (Electrónica, Electricidad, Electromecánica, Soldadura):**
    - No existe un **registro claro** de la topología en estas áreas.
    - Se ha detectado una **pérdida significativa de paquetes**, lo que sugiere problemas en cableado, equipamiento o configuración.
	
- **Servidores de red adicionales:**
    - Existen PCs que actúan como **servidores DHCP** en los laboratorios.
    - Son equipos antiguos, con software obsoleto, lo que implica riesgos de **fallas y dificultades de administración**.

## Problemas de Gestión y Documentación

- **Ausencia de documentación:**
    - No se dispone de un **mapa lógico ni físico actualizado** de la red.
    - Falta de **rotulación en cables, rosetas, switches, patcheras y racks**.

Esto complica la tarea de diagnóstico, mantenimiento y escalabilidad de la red.

## Riesgos Identificados

1. **Seguridad:** uso de software sin soporte oficial.    
2. **Rendimiento:** limitaciones en switch principal y cableado troncal.
3. **Escalabilidad:** difícil migración hacia mayores velocidades de internet.
4. **Confiabilidad:** pérdidas de paquetes en sectores críticos.
5. **Gestión deficiente:** falta de documentación y rotulación.
6. **Mal uso de los recursos:** No se estan aprovechando los 200 Mbps.
## Recomendaciones de Mejora

1. **Reemplazo del servidor “Pan Casero”:**
    - Sustituirlo por un **router/firewall profesional** con soporte actualizado.
    - Opciones: **MikroTik, Ubiquiti, Fortinet o similares**.
    
2. **Actualización del switch principal:**
    - Migrar a un **switch gigabit gestionable (1 Gbps)** que permita segmentar y priorizar tráfico (VLANs, QoS).
    
3. **Normalización del cableado:**
    - Sustituir tramos de **CAT5e por CAT6 o superior** en enlaces troncales y de entrada de internet.
    - Certificar cableado para asegurar el rendimiento.
    
4. **Infraestructura WiFi moderna:**
    - Instalar **access points de alta densidad** en laboratorios y preceptorías.
    - Planificar la cobertura para evitar zonas sin señal.
    
5. **Centralización de servicios de red (DHCP, firewall, VPN):**
    - Unificar los servicios en el nuevo router/firewall.
    - Eliminar PCs obsoletas que cumplen estas funciones.
    
6. **Documentación y rotulación:** 
    - Elaborar un **mapa lógico y físico** de la red.
    - Implementar un sistema de **etiquetado en cables, rosetas, switches y patcheras**.
    
7. **Monitoreo de red:**
    - Implementar herramientas de **medición y alertas** (ej. Zabbix, PRTG, The Dude).
    - Permitir un seguimiento activo de caídas, saturaciones o pérdidas de paquetes.

---

## Conclusión

La red actual funciona, pero presenta **serias limitaciones estructurales, de seguridad y de gestión**.  
Si bien la velocidad contratada a Telecom cubre las necesidades inmediatas, los cuellos de botella y la falta de planificación pueden obstaculizar el crecimiento del colegio a corto plazo.

Un plan de actualización en **tres fases (equipamiento principal, cableado y WiFi, documentación y monitoreo)** permitirá contar con una red **más rápida, segura, escalable y confiable**, alineada con las necesidades actuales y futuras de la institución.