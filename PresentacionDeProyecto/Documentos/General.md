# Informe General de Relevamiento y Plan de Mejora de la Red del Colegio

---

## 1. Situación Actual

En la actualidad, la red del colegio se encuentra centralizada en una PC conocida como **“Pan Casero”**, que cumple la función de servidor de red.  
Este equipo utiliza **Zeroshell**, una distribución Linux orientada a redes (router, firewall, servidor VPN y gestor de red avanzado).

- Lanzamiento: **2006**  
- Última versión estable: **2017**  
- Fin de vida (EOL): **2018**

Al estar desactualizada, esta herramienta representa un **riesgo en términos de seguridad y eficiencia**, lo que puede impactar en la estabilidad general de la red.

### Equipamiento Principal

- **Switch principal:** distribuye el tráfico hacia los distintos sectores del colegio (laboratorios de programación, electrónica, electromecánica, administración, dirección, etc.).  
  - Velocidad máxima: **100 Mbps**  
  - Limitante: todas las redes internas soportan hasta **1000 Mbps (1 Gbps)**, por lo que el switch restringe el rendimiento a un **10% de la capacidad máxima**.  
  - El servicio actual de **Telecom Integra** brinda **200 Mbps**, suficiente para el presente, pero este cuello de botella impedirá escalar a mayores velocidades en el futuro.

- **Cableado estructurado:**  
  - Laboratorios de programación: cableado con **CAT6** (hasta **1 Gbps a 100 m** y hasta **10 Gbps a 55 m**).  
  - Otras áreas: parte del cableado es **CAT5e** (hasta **1 Gbps a 100 m**).  
  - Problema detectado: el cable de entrada de Internet hacia *Pan Casero* es **CAT5e**, generando un **cuello de botella en el primer eslabón de la red**.

- **Conectividad inalámbrica (WiFi):**  
  - Sectores sin cobertura (ej. preceptorías planta baja).  
  - **Access Points actuales saturados** por la cantidad de dispositivos.  
  - Muchas computadoras modernas ya no incluyen puerto **RJ45 (Ethernet)** → necesidad de reforzar la infraestructura WiFi.

- **Laboratorios técnicos (Electrónica, Electricidad, Electromecánica, Soldadura):**  
  - No existe un **registro claro** de la topología.  
  - Se detectan **pérdidas significativas de paquetes**.

- **Servidores DHCP adicionales:**  
  - Existen PCs que actúan como **servidores DHCP en laboratorios**.  
  - Son equipos antiguos y obsoletos.  

### Problemas de Gestión y Documentación

- No se dispone de un **mapa lógico ni físico actualizado**.  
- Falta de **rotulación en cables, rosetas, switches, patcheras y racks**.  

### Riesgos Identificados

1. **Seguridad:** uso de software sin soporte oficial.  
2. **Rendimiento:** limitaciones en switch principal y cableado troncal.  
3. **Escalabilidad:** difícil migración hacia mayores velocidades de internet.  
4. **Confiabilidad:** pérdidas de paquetes en sectores críticos.  
5. **Gestión deficiente:** falta de documentación y rotulación.  
6. **Mal uso de los recursos:** no se aprovechan los **200 Mbps simétricos dedicados** contratados.  

---

## 2. Plan de Modernización

El plan se estructura en **cinco fases**, con el objetivo de modernizar, normalizar y escalar la red del colegio, garantizando **mayor velocidad, seguridad, confiabilidad y facilidad de gestión**.

### Fase 1 – Reemplazo de “Pan Casero” y switch principal

- Sustituir por un **MikroTik CCR2004-16G-2S+**, que permitirá unificar funciones:  
  - Router principal  
  - Firewall  
  - Servidor DHCP y VPN  
  - Switch central gigabit (1 Gbps)  

#### Beneficios
- Se eliminan cuellos de botella → de 100 Mbps a **1 Gbps por puerto**.  
- Centralización de seguridad → bloqueo de **juegos online y contenido adulto** a nivel de red.  
- Red más limpia → menos consumo indebido de ancho de banda.  
- Compatibilidad futura con velocidades mayores a 200 Mbps.  

#### Acciones
- Replicar configuración de Pan Casero (rutas, NAT, firewall, DHCP).  
- Implementar listas de bloqueo y segmentar la red en **VLANs** (laboratorios, docentes, administración, alumnos).  

#### Momento de Implementación
Lo ideal seria comenzar esta fase a fines de noviembre de 2025, ya que hay menos alumnos por lo que si hay algún corte de internet, no sea tan critico. Y lo ideal seria terminarlo en una semana para empezar con la fase dos.

---

### Fase 2 – Normalización de laboratorios de programación

- **Unificación de la lógica de red:** switches, patcheras y routers con la misma topología.  
- **Etiquetado completo:** cables, rosetas, patcheras y switches.  
- **Mapas de red:** diagramas lógicos y físicos actualizados.  

#### Beneficios
- Facilita diagnóstico y reparación.  
- Reduce tiempos de mantenimiento.  
- Establece un estándar replicable en otros sectores.  

#### Momento de Implementación
Diciembre de 2025

---

### Fase 3 – Migración a redes híbridas (cableadas + WiFi)

- Reemplazar PCs que cumplen rol de DHCP en laboratorios por **MikroTik hAP ax³**.  
  - Router + DHCP + **WiFi 6 dual-band (2.4 y 5 GHz)**.  
- Mantener cableado para PCs, pero agregar cobertura WiFi para notebooks, tablets y celulares.  

#### Beneficios
- Elimina equipos obsoletos.  
- Cada laboratorio contará con red **estable, híbrida y moderna**.  
- Compatibilidad con equipos actuales sin puerto Ethernet.  

#### Momento de Implementación
Inicios de 2026

---

### Fase 4 – Normalización de los demás laboratorios

- Relevamiento de cableado y equipos en Electrónica, Electricidad, Electromecánica y Soldadura.  
- Sustituir tramos CAT5e defectuosos por **CAT6 o superior**.  
- Reemplazar switches viejos por **switches gigabit gestionables**.  
- Unificar lógica de red con la de laboratorios de programación.  

#### Beneficios
- Red confiable y homogénea en todo el colegio.  
- Eliminación de pérdidas de paquetes. 

#### Momento de Implementación
Durante 2026

---

### Fase 5 – Optimización de la red central (ITSV_CENTRAL)

- Rediseñar la topología central.  
- Instalar **MikroTik cAP ax** en pasillos y aulas, comenzando con uno en fase piloto.  
- Configuración unificada (CAPsMAN o equivalente).  

#### Beneficios
- WiFi estable y disponible en toda la institución.  
- Mejor gestión de múltiples dispositivos.  
- Facilidad de escalamiento a futuro.  

#### Momento de Implementación
Fines de 2026

---

## 3. Herramientas de Soporte

### Proskit MT-7059

El **Proskit MT-7059** es una herramienta profesional de diagnóstico y certificación de cableado de red. Su compra es esencial para acompañar la modernización.  

#### Funciones principales
- **Wiremap completo:** detecta abiertos, cortos, pares cruzados, inversión de polaridad, blindaje incorrecto.  
- **Prueba de continuidad y fallas:** localiza tramos defectuosos rápidamente.  
- **Localización de cables en campo:** rastreo hasta **2 km** con 9 tonos seleccionables.  
- **Compatibilidad múltiple:** RJ45, RJ11, coaxial, USB, IEEE 1394.  
- **Pruebas avanzadas:** detección de blindaje, continuidad en patcheras y rosetas.  

#### Beneficios
- **Ahorro de tiempo y recursos:** fallas localizadas en minutos.  
- **Mayor confiabilidad:** asegura que el cableado soporte **200 Mbps actuales y 1 Gbps futuros**.  
- **Prevención de problemas:** identifica tramos defectuosos antes de cortes o caídas.  
- **Uso educativo:** estudiantes de electrónica y programación podrán usarlo como herramienta formativa.  

---

## 4. Presupuesto y Fases de Inversión

- **Fase 1:**  
  - MikroTik CCR2004-16G-2S+  
  - 1 MikroTik hAP ax³ (prueba en laboratorio FAT)  
  - Proskit MT-7059 (herramienta de diagnóstico)  
  - Rollo de cable CAT6
  - Terminales CAT6

- **Fase 2:**  
  - Implementación de MikroTik hAP ax³ en laboratorios de programación (Lab 1, Lab 2 y Lab 3).  
  - Normalización y documentación.
  - Materiales necesarios para dejar los labs en condiciones.

- **Fase 3:**  
  - Migración y normalización de laboratorios técnicos.  
  - Cada uno equipado con MikroTik hAP ax³. 
  - Materiales necesarios para dejar los labs en condiciones.

- **Fase 4:**  
  - Implementación de red WiFi en las alas del colegio con MikroTik cAP ax.  
  - Prueba piloto → implementación masiva.
  - Materiales necesarios para dejar las areas en condiciones.

---

## 5. Características de los productos MikroTik y fundamentos de elección

### MikroTik CCR2004-16G-2S+

- **16 puertos Gigabit Ethernet + 2 puertos SFP+ 10 Gbps.**  
- **CPU de 4 núcleos a 1,7 GHz.**  
- **Throughput real >7 Gbps.**  
- Soporte completo de RouterOS (firewall, VPN, NAT, VLAN, QoS, listas de bloqueo).  
- Permite reemplazar *Pan Casero* y el switch principal en un único equipo.  

**Motivo de elección:** costo-beneficio superior a alternativas Cisco o Fortinet, escalabilidad y capacidad de gestión centralizada.

### MikroTik hAP ax³

- Router WiFi 6 dual-band (2.4/5 GHz).  
- **5 puertos Gigabit Ethernet.**  
- CPU ARM de 4 núcleos a 1,8 GHz + 1 GB RAM.  
- Soporte de CAPsMAN para gestión centralizada.  
- Puede funcionar como router, DHCP, firewall y AP en un único dispositivo.  

**Motivo de elección:** reemplaza PCs obsoletas como servidores DHCP, asegura redes híbridas modernas y económicas en laboratorios.

### MikroTik cAP ax

- Access Point WiFi 6 dual-band para montaje en techo/pared.  
- Alimentación vía PoE.  
- Compatible con CAPsMAN para administración unificada.  
- Diseñado para entornos de alta densidad de usuarios.  

**Motivo de elección:** expansión de WiFi estable y escalable en todo el colegio, con gestión centralizada y bajo costo.

---

## 6. Conclusión

La red actual del colegio presenta **limitaciones críticas** de seguridad, rendimiento y escalabilidad. La propuesta presentada resuelve estas falencias mediante un **plan integral en cinco fases**, que combina:

- **Equipamiento robusto y escalable (MikroTik CCR2004, hAP ax³, cAP ax).**  
- **Herramientas de diagnóstico profesionales (Proskit MT-7059).**  
- **Normalización, documentación y segmentación de la red.**  
- **Infraestructura WiFi moderna y confiable.**  

Con estas acciones, el colegio contará con una red **rápida, segura, documentada y preparada para el futuro**, optimizando los **200 Mbps simétricos dedicados actuales** y garantizando la posibilidad de escalar sin dificultades.  


# 7. Fuentes
https://mikrotik.com/product/ccr2004_16g_2splus
https://mikrotik.com/product/hap_ac3
http://mikrotik.com/product/cap_ax

https://www.mercadolibre.com.ar/tester-de-red-viru-viru-proskit-mt-7059-display-lcd/p/MLA36022100#polycard_client=search-nordic&search_layout=grid&position=23&type=product&tracking_id=01c05991-06e4-49b4-a4ea-bc4949932edf&wid=MLA1501523933&sid=search
https://www.mercadolibre.com.ar/router-mikrotik-routerboard-hap-ac3-rbd53ig-5hacd2hnd-negro/p/MLA18543900#polycard_client=search-nordic&search_layout=grid&position=3&type=product&tracking_id=62a983b0-2fd6-40de-acb7-1873bf02d451&wid=MLA1399582563&sid=search
https://www.mercadolibre.com.ar/access-point-mikrotik-capgi-5haxd2haxd-dual-band-1800-mbps-color-blanco/p/MLA29388286#polycard_client=search-nordic&search_layout=stack&position=1&type=product&tracking_id=04b20e11-5514-493a-9c28-e3843da7141a&wid=MLA1535042599&sid=search
https://www.mercadolibre.com.ar/bobina-rollo-de-cable-utp-glc-305m-cat-6-interior/p/MLA34362030#polycard_client=search-nordic&search_layout=stack&position=3&type=product&tracking_id=6704d102-4327-4359-b4cd-ac07139134b7&wid=MLA1421317339&sid=search