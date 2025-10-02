A continuación, se presenta un plan estructurado en fases para modernizar, normalizar y escalar la red del colegio, garantizando **mayor velocidad, seguridad, confiabilidad y facilidad de gestión**.

---

## 1. Reemplazo de “Pan Casero” y del switch principal

- Sustituir el servidor actual (**Pan Casero**) y el switch de **100 Mbps** por un **MikroTik CCR2004-16G-2S+**.
    
- Este equipo permitirá unificar las funciones de:
    - **Router principal**
    - **Firewall**
    - **Servidor DHCP y VPN**
    - **Switch central gigabit (1 Gbps)**

### Beneficios

- **Eliminación de cuellos de botella:** se pasa de 100 Mbps a **1 Gbps por puerto**.

- **Centralización de la seguridad:**    
    - Configuración de firewall y filtros de contenido a nivel central.
    - Bloqueo de **juegos en línea, contenido adulto y otros sitios no educativos**, sin necesidad de configurar red por red.
    
- **Red más limpia:** se reduce el consumo de ancho de banda destinado a usos indebidos.

- **Compatibilidad futura:** el CCR2004 soporta escalabilidad para velocidades superiores y más conexiones simultáneas.

### Acciones

- Replicar la configuración de Pan Casero en el Mikrotik (rutas, NAT, reglas de firewall, DHCP, etc.).
- Implementar filtrado de contenido por direcciones/dominios (ej. listas de bloqueo).
- Segmentar la red en **VLANs** para laboratorios, administración, docentes y alumnos, con prioridades y límites de tráfico (QoS).

---

## 2. Normalización, documentación y rotulado de laboratorios de programación

Estos laboratorios son los más documentados actualmente, por lo que se propone iniciar la normalización con ellos.

### Acciones

- **Unificación de la lógica de red:**
    - Estandarizar la conexión entre switches, patcheras y routers.
    - Asegurar que todos los laboratorios sigan la misma topología.
        
- **Etiquetado completo:**
    - Rotular todos los cables, rosetas, patcheras y switches.
    - Ejemplo: indicar claramente el tramo _Switch 1 → Patchera 3 → Roseta 5 (Aula 2)_.
        
- **Mapas de red:** generar diagramas físicos y lógicos accesibles para el área de sistemas.

### Beneficios

- Facilita el diagnóstico y reparación ante fallas.
- Reduce tiempos de mantenimiento.
- Establece un estándar replicable en otras áreas.

---

## 3. Migración de laboratorios a redes híbridas (cableadas + WiFi)

Actualmente, algunos laboratorios cuentan con PCs que funcionan como servidores DHCP, lo cual es obsoleto.

### Acciones

- Reemplazar estas PCs por **MikroTik hAP ax³**:
    - Funcionan como **router, servidor DHCP y access point WiFi 6**.
    - Ofrecen **dual-band** (2,4 y 5 GHz) para soportar más dispositivos.
    
- Mantener el cableado para PCs que lo requieran, pero agregar cobertura WiFi para notebooks, tablets y celulares.

### Beneficios

- Se elimina la dependencia de PCs viejas como servidores de red.
- Se asegura que cada laboratorio tenga una red mixta **estable y moderna**.
- Compatibilidad con equipos actuales que ya no incluyen puerto Ethernet (RJ45).

---

## 4. Normalización y optimización de otros laboratorios

En las áreas de **Electrónica, Electromecánica, Electricidad y Soldadura**, actualmente no existe un registro completo de la red y se detectan pérdidas de paquetes.

### Acciones

- Relevar y documentar el cableado y los equipos de red.    
- Detectar tramos defectuosos o mal instalados.
- Sustituir cableado obsoleto (ej. CAT5e en enlaces troncales) por **CAT6 o superior**.
- Reemplazar switches antiguos por **switches gigabit gestionables**.
- Unificar la lógica de red con la misma estructura implementada en los laboratorios de programación.

### Beneficios

- Red más confiable y con menor pérdida de paquetes.
- Homogeneización de toda la infraestructura del colegio.

---

## 5. Optimización de la red central (ITSV_CENTRAL)

Actualmente, la cobertura WiFi es insuficiente en algunas áreas (ej. preceptorías y aulas alejadas).

### Acciones

- Rediseñar la topología de la red central.    
- Instalar **Access Points de alta densidad** (cAP ax) en las distintas alas del colegio.
- Configurar los APs bajo un esquema unificado.

### Beneficios

- Conectividad WiFi estable y disponible en todas las aulas.
- Red más eficiente en la gestión de múltiples dispositivos (profesores + alumnos).
- Mayor facilidad para escalar la red en el futuro.

---

## Conclusión

Este plan aborda la **modernización integral** de la red en cinco fases:

1. Reemplazo del servidor y switch principal por un equipo robusto y moderno.
2. Normalización y documentación inicial en laboratorios de programación.
3. Migración a redes híbridas con equipos WiFi 6.
4. Optimización de laboratorios técnicos.
5. Rediseño de la red central para cobertura total en aulas.

Con estas acciones, el colegio contará con una red **más rápida, segura, documentada y preparada para el futuro**, garantizando el correcto desarrollo de las actividades educativas.