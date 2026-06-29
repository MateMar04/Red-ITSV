# VPN alumnos - WireGuard

Esta guia explica como instalar WireGuard, generar las claves necesarias y conectarse a la VPN de alumnos para administrar el servidor Ubuntu por SSH.

## Alcance de esta VPN

La VPN de alumnos permite acceder solamente al servidor Ubuntu:

```text
Servidor Ubuntu: 192.168.0.100
Servicio permitido: SSH, puerto 22
```

No da acceso de administracion al router MikroTik ni al resto de la red interna.

## 1. Instalar WireGuard

Descargar WireGuard desde la pagina oficial:

```text
https://www.wireguard.com/install/
```

Opciones habituales:

| Sistema | Instalacion |
|---|---|
| Windows | Descargar el instalador desde la pagina oficial |
| macOS | Instalar desde App Store |
| Android | Instalar desde Play Store |
| iOS / iPadOS | Instalar desde App Store |
| Ubuntu / Debian | `sudo apt install wireguard` |

## 2. Crear un tunel nuevo

En la app de WireGuard:

1. Abrir WireGuard.
2. Crear un tunel nuevo.
3. Elegir la opcion de tunel vacio, manual o desde cero.
4. La app genera automaticamente dos claves:
   - `PrivateKey`: clave privada.
   - `PublicKey`: clave publica.

## 3. Enviar la clave publica

Enviar al administrador solamente la clave publica:

```text
PublicKey = PEGAR_AQUI_LA_CLAVE_PUBLICA
```

No enviar nunca la clave privada.

La clave privada debe quedar guardada solo en el dispositivo del alumno.

## 4. Esperar la IP asignada

El administrador va a registrar la clave publica en el MikroTik y asignar una IP de VPN.

Ejemplos:

```text
Alumno 1: 10.10.20.2/32
Alumno 2: 10.10.20.3/32
Alumno 3: 10.10.20.4/32
```

Cada alumno debe usar solamente la IP que le fue asignada.

## 5. Configurar el tunel

Cuando el administrador entregue los datos finales, completar el tunel con este formato:

```ini
[Interface]
PrivateKey = CLAVE_PRIVADA_DEL_ALUMNO
Address = 10.10.20.2/32
DNS = 192.168.0.1

[Peer]
PublicKey = wNnmMpcdr2fACQ5fOIqeAMpwiSnTnBVN0EpWCDY0bzQ=
Endpoint = 181.10.31.114:13232
AllowedIPs = 10.10.20.0/24, 192.168.0.100/32
PersistentKeepalive = 25
```

Valores a reemplazar:

| Campo | Que colocar |
|---|---|
| `CLAVE_PRIVADA_DEL_ALUMNO` | La clave privada generada en la app del alumno |
| `10.10.20.2/32` | La IP asignada por el administrador. Cambiarla si se asigno otra, por ejemplo `10.10.20.3/32` |


## 6. Conectar la VPN

Activar el tunel desde la app de WireGuard.

Si la conexion fue exitosa, deberia aparecer como activa.

## 7. Probar conectividad

Primero probar ping al gateway de la VPN:

```bash
ping 10.10.20.1
```

Si responde, la VPN esta activa. Para entrar al servidor Ubuntu todavia falta configurar el acceso SSH.

## 8. Crear acceso SSH

Para entrar al servidor Ubuntu no se debe compartir la contrasena del usuario. Cada alumno debe generar una clave SSH y enviar solamente su clave publica al administrador.

### 8.1. Generar clave SSH

En Windows, macOS o Linux, abrir una terminal y ejecutar:

```bash
ssh-keygen -t ed25519 -C "alumno@itsv"
```

Cuando pregunte donde guardar la clave, se puede presionar Enter para usar la ubicacion por defecto.

Cuando pregunte passphrase, se recomienda colocar una contrasena para proteger la clave privada. Tambien se puede presionar Enter para dejarla sin passphrase si el administrador lo autoriza.

Esto genera dos archivos:

```text
Clave privada: ~/.ssh/id_ed25519
Clave publica: ~/.ssh/id_ed25519.pub
```

La clave privada no se comparte.

### 8.2. Enviar clave publica SSH

Mostrar la clave publica:

```bash
cat ~/.ssh/id_ed25519.pub
```

Enviar al administrador la linea completa. Debe empezar con algo similar a:

```text
ssh-ed25519 AAAA...
```

No enviar el archivo `id_ed25519`.

### 8.3. Cargar la clave en el servidor Ubuntu

Este paso lo hace el administrador en el servidor Ubuntu.

Si todos los alumnos usan el mismo usuario, por ejemplo `panca`, agregar la clave publica al archivo:

```bash
sudo mkdir -p /home/panca/.ssh
sudo nano /home/panca/.ssh/authorized_keys
```

Pegar la clave publica del alumno en una linea nueva.

Luego corregir permisos:

```bash
sudo chown -R panca:panca /home/panca/.ssh
sudo chmod 700 /home/panca/.ssh
sudo chmod 600 /home/panca/.ssh/authorized_keys
```

Si cada alumno tiene su propio usuario, crear el usuario y cargar la clave en su `authorized_keys`:

```bash
sudo adduser alumno1
sudo usermod -aG docker alumno1

sudo mkdir -p /home/alumno1/.ssh
sudo nano /home/alumno1/.ssh/authorized_keys

sudo chown -R alumno1:alumno1 /home/alumno1/.ssh
sudo chmod 700 /home/alumno1/.ssh
sudo chmod 600 /home/alumno1/.ssh/authorized_keys
```

Agregar alumnos al grupo `docker` les da permisos altos sobre el servidor. Usarlo solo si realmente necesitan administrar contenedores.

### 8.4. Probar acceso SSH

Con la VPN conectada, el alumno debe ejecutar:

```bash
ssh USUARIO@192.168.0.100
```

Ejemplo:

```bash
ssh panca@192.168.0.100
```

Si uso una clave con nombre distinto al predeterminado:

```bash
ssh -i ~/.ssh/NOMBRE_DE_LA_CLAVE USUARIO@192.168.0.100
```

### 8.5. Recomendaciones para el administrador

En el servidor Ubuntu, permitir SSH desde la VPN de alumnos:

```bash
sudo ufw allow from 10.10.20.0/24 to any port 22 proto tcp
sudo ufw status
```

Cuando ya este probado el acceso por clave, deshabilitar acceso SSH por contrasena:

```bash
sudo nano /etc/ssh/sshd_config
```

Verificar o ajustar estas lineas:

```text
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
```

Aplicar cambios:

```bash
sudo systemctl reload ssh
```

Antes de cerrar la sesion actual, abrir otra terminal y confirmar que el acceso por clave funciona.

## 9. Generar claves WireGuard desde terminal

Este paso es opcional. Sirve para Linux o macOS si se prefiere usar terminal.

```bash
wg genkey | tee alumno-private.key | wg pubkey > alumno-public.key
```

Ver clave publica:

```bash
cat alumno-public.key
```

Ver clave privada:

```bash
cat alumno-private.key
```

Enviar al administrador solamente el contenido de:

```bash
cat alumno-public.key
```

## Reglas de seguridad

- No compartir la clave privada.
- No publicar capturas donde se vea la clave privada.
- Avisar al administrador si se pierde el dispositivo o se sospecha que la clave fue copiada.
- Usar solamente la IP VPN asignada.
- La VPN no enruta todo Internet, solo el acceso a `192.168.0.100`.
- No compartir la clave privada SSH.
- Avisar al administrador si se pierde una notebook con acceso SSH configurado.

## Problemas frecuentes

| Problema | Posible causa |
|---|---|
| No conecta | La clave publica no fue cargada en el MikroTik o el endpoint/puerto no es correcto |
| Conecta pero no responde ping | Revisar si el tunel esta activo y si la IP asignada coincide |
| Conecta pero no entra por SSH | Revisar usuario SSH, permisos de clave SSH y firewall del servidor Ubuntu |
| Internet cambia al activar VPN | Revisar que `AllowedIPs` no sea `0.0.0.0/0`; debe ser `10.10.20.0/24, 192.168.0.100/32` |
