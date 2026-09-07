# 🧪 Comandos de verificación — Parte 1 · DNS Maestro/Esclavo

**Parcial 1 — Servicios Telemáticos · UAO**
Dominio `empresa.local` · Zona inversa `50.168.192.in-addr.arpa`

| Rol | Hostname | IP |
| :--- | :--- | :--- |
| VM1 — DNS maestro | `maestro` | `192.168.50.3` |
| VM2 — DNS esclavo | `esclavo` | `192.168.50.2` |
| Cliente | Anfitrión Windows | `192.168.50.1` |

> 🔴 = ejecutar en el **maestro** · 🔵 = en el **esclavo** · 🪟 = en **PowerShell (Windows)**

---

## 🖥️ Gestión del entorno

🪟 Desde `C:\vagrant\parcial1`

```powershell
vagrant status              # estado de las dos VMs
vagrant up maestro          # encender el maestro
vagrant up esclavo          # encender el esclavo
vagrant ssh maestro         # entrar al maestro
vagrant ssh esclavo         # entrar al esclavo
vagrant halt maestro        # apagar el maestro (prueba de continuidad)
```

---

## 📐 Requisito 1 — BIND9 en las dos VMs

Identidad de la máquina — 🔴 🔵

```bash
hostname                        # maestro / esclavo
ip a show eth1 | grep "inet "   # 192.168.50.3 / 192.168.50.2
free -h                         # RAM asignada
```

Estado del servicio — 🔴 🔵

```bash
systemctl status named --no-pager   # debe decir: active (running)
sudo ss -tulnp | grep :53           # udp y tcp escuchando en el puerto 53
named-checkconf                     # sin salida = sin errores de sintaxis
sudo ufw status                     # Status: inactive
```

> El paquete se llama **`bind9`** pero el servicio se llama **`named`**.
> El puerto 53 usa **UDP** para consultas normales y **TCP** para respuestas grandes y transferencias de zona.

---

## 🗂️ Requisito 2 — Zona directa `empresa.local`

Validación de sintaxis — 🔴

```bash
sudo named-checkconf
sudo named-checkzone empresa.local /etc/bind/db.empresa.local
```

Resolución directa — 🔴

```bash
dig @192.168.50.3 www.empresa.local A +short      # 192.168.50.3
dig @192.168.50.3 www.empresa.local AAAA +short   # fd00:50::3
dig @192.168.50.3 empresa.local MX +short         # 10 mail.empresa.local.
dig @192.168.50.3 empresa.local NS +short         # ns1 y ns2
dig @192.168.50.3 ftp.empresa.local +short        # el CNAME y luego la IP
dig @192.168.50.3 empresa.local SOA +short        # serial y los 5 tiempos
```

**SOA:** serial `AAAAMMDDNN` · refresh `3600` (1 h) · retry `600` (10 min) · expire `1209600` (14 días) · minimum `300` (5 min)

---

## 🔁 Requisito 3 — Zona inversa y registros PTR

Validación — 🔴

```bash
sudo named-checkzone 50.168.192.in-addr.arpa /etc/bind/db.192.168.50
```

Resolución inversa — 🔴 🔵

```bash
dig @192.168.50.3 -x 192.168.50.3 +short    # maestro.empresa.local.
dig @192.168.50.3 -x 192.168.50.2 +short    # esclavo.empresa.local.
dig @192.168.50.3 -x 192.168.50.1 +short    # cliente.empresa.local.
dig @192.168.50.3 -x 192.168.50.10 +short   # pc01.empresa.local.
```

> `dig -x 192.168.50.3` equivale a `dig 3.50.168.192.in-addr.arpa PTR`

---

## 🔄 Requisito 4 — NOTIFY y transferencia AXFR / IXFR

Verificar que la copia llegó — 🔵

```bash
sudo ls -l /var/cache/bind/     # db.empresa.local y db.192.168.50, dueño bind
sudo rndc retransfer empresa.local
sudo rndc retransfer 50.168.192.in-addr.arpa
```

El esclavo responde como servidor — 🔵

```bash
dig @192.168.50.2 www.empresa.local A +short
dig @192.168.50.2 -x 192.168.50.10 +short
dig @192.168.50.2 empresa.local SOA +short
```

Diagnóstico de rutas (problema resuelto de origen multi-interfaz) — 🔵

```bash
ip route
ip route get 192.168.50.3      # debe salir: dev eth1 src 192.168.50.2
```

---

## 🔐 Requisito 5 — Transferencia segura con TSIG

Generar la clave — 🔴

```bash
tsig-keygen -a HMAC-SHA256 esclavo-key
```

**Prueba A — sin clave, desde la IP autorizada → debe FALLAR** — 🔵

```bash
dig -b 192.168.50.2 @192.168.50.3 empresa.local AXFR
```

**Prueba B — con clave → debe FUNCIONAR** — 🔵

```bash
sudo dig @192.168.50.3 empresa.local AXFR -k /etc/bind/keys/esclavo.key
```

**Prueba C — desde fuera, sin clave → debe FALLAR** — 🪟

```powershell
nslookup -type=axfr empresa.local 192.168.50.3
```

Evidencia en los logs — 🔴

```bash
sudo tail -20 /var/log/named/security.log
```

> Misma IP, mismo comando: sin clave rechazado, con clave autorizado.
> Lo que autoriza es la **firma criptográfica**, no la dirección de origen.

---

## 🔃 Requisito 6 — Sincronización automática

Estado antes del cambio

```bash
dig @192.168.50.3 empresa.local SOA +short
dig @192.168.50.2 empresa.local SOA +short
```

Modificar y recargar — 🔴

```bash
sudo vim /etc/bind/db.empresa.local     # subir el serial + agregar un registro
sudo named-checkzone empresa.local /etc/bind/db.empresa.local
sudo rndc reload
```

> ⚠️ **`rndc reload`, NO `systemctl restart`**: el restart mata el proceso, BIND pierde
> la copia en memoria y no puede calcular el delta → el esclavo recibe AXFR en vez de IXFR.

Verificar en el esclavo **sin tocarlo** — 🔵

```bash
dig @192.168.50.2 empresa.local SOA +short
dig @192.168.50.2 soporte.empresa.local A +short
dig @192.168.50.2 -x 192.168.50.20 +short
sudo tail -20 /var/log/named/transfers.log
```

---

## 🛡️ Requisito 7 — Hardening

**Dominios externos → deben FALLAR** — 🔴 🔵

```bash
dig @192.168.50.3 google.com +short      # vacío
dig @192.168.50.2 google.com +short      # vacío
dig @192.168.50.2 google.com | head -8   # status: REFUSED, sin el flag 'ra'
```

**La zona propia → debe seguir funcionando**

```bash
dig @192.168.50.2 www.empresa.local +short
dig @192.168.50.2 -x 192.168.50.3 +short
```

**Versión oculta**

```bash
dig @192.168.50.3 version.bind CHAOS TXT +short   # "no disponible"
```

**Rate limiting — provocarlo** — 🔴

```bash
for i in $(seq 1 300); do dig @192.168.50.3 www.empresa.local +short > /dev/null; done
```

```bash
sudo tail -10 /var/log/named/rate-limit.log
```

Confirmar que las directivas quedaron cargadas

```bash
sudo named-checkconf -p | grep -A4 rate-limit
sudo named-checkconf -p | grep -E "recursion|allow-query|version"
```

> `slip` = respuesta truncada que fuerza reintento por TCP (imposible con IP falsificada).
> `drop` = respuesta descartada en silencio.

---

## 📜 Requisito 8 — Auditoría

Los cuatro archivos — 🔴 🔵

```bash
sudo ls -l /var/log/named/
sudo tail -10 /var/log/named/queries.log      # quién consultó qué
sudo tail -20 /var/log/named/transfers.log    # notify + xfer-in + xfer-out
sudo tail -10 /var/log/named/security.log     # AXFR denegados
sudo tail -10 /var/log/named/rate-limit.log   # slip y drop
```

> El directorio es `750` con dueño `bind`, por eso hace falta `sudo` para leerlo.
> Para copiar con comodín: `sudo sh -c 'cp /var/log/named/*.log /destino/'`

---

## 🏁 Requisito 9 — Continuidad del servicio

Configurar el cliente para que apunte **solo** al esclavo — 🪟 *(como Administrador)*

```powershell
Get-DnsClientServerAddress -AddressFamily IPv4 | Format-Table -AutoSize
Set-DnsClientServerAddress -InterfaceAlias "Ethernet 3" -ServerAddresses 192.168.50.2
Set-DnsClientServerAddress -InterfaceAlias "vEthernet (WSL (Hyper-V firewall))" -ResetServerAddresses
ipconfig /flushdns
```

Apagar el maestro — 🪟

```powershell
vagrant halt maestro
vagrant status
ping 192.168.50.3                              # debe fallar
nslookup www.empresa.local 192.168.50.3        # debe dar timeout
```

**Prueba final: el cliente sigue resolviendo** — 🪟

```powershell
nslookup www.empresa.local      # A + AAAA
nslookup mail.empresa.local     # A
nslookup ftp.empresa.local      # CNAME, muestra "Aliases:"
nslookup 192.168.50.3           # PTR -> maestro.empresa.local
nslookup 192.168.50.10          # PTR -> pc01.empresa.local
```

Restaurar — 🪟

```powershell
vagrant up maestro
```

> El esclavo sobrevive hasta el **expire** del SOA: **14 días**.
> Pasado ese plazo deja de responder, porque una respuesta desactualizada
> es peor que ninguna.

---

## 🐙 Entrega al repositorio

🔴 En el maestro

```bash
sudo cp /etc/bind/named.conf.local /etc/bind/named.conf.options \
        /etc/bind/db.empresa.local /etc/bind/db.192.168.50 \
        /vagrant/parte-1-dns/maestro/
sudo cp /etc/bind/keys/esclavo.key /vagrant/parte-1-dns/tsig/
sudo sh -c 'cp /var/log/named/*.log /vagrant/parte-1-dns/logs/'
```

🔵 En el esclavo

```bash
sudo cp /etc/bind/named.conf.local /etc/bind/named.conf.options \
        /etc/netplan/99-parcial.yaml /vagrant/parte-1-dns/esclavo/
sudo cp /var/cache/bind/db.empresa.local /var/cache/bind/db.192.168.50 \
        /vagrant/parte-1-dns/esclavo/
```

🪟 En Windows

```powershell
cd C:\vagrant\parcial1
git add .
git commit -m "mensaje"
git push
```
