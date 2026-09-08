# Análisis de seguridad — Parte 3

**Parcial 1 · Servicios Telemáticos · Universidad Autónoma de Occidente**

---

## Riesgos de exponer el servidor con un túnel público

### Superficie de exposición

Mientras trabajamos las partes 1 y 2, al servidor solo podían llegarle peticiones desde
las tres máquinas de la red 192.168.50.0/24. Al levantar el túnel eso cambia por
completo: ahora puede recibir peticiones de cualquier equipo conectado a Internet.

Hay un detalle del funcionamiento del túnel que conviene entender. `cloudflared` no abre
ningún puerto en el servidor. Lo que hace es conectarse él mismo hacia Cloudflare, y por
esa conexión ya establecida entran después las peticiones. Como la conexión sale desde
adentro, el firewall la ve igual que cuando abrimos una página web y no la bloquea. Por
eso un túnel permite publicar un servicio sin tocar la configuración del router, pero
también por eso evita los controles de red que una organización pueda tener puestos.

También hay que contar lo que el servidor le muestra a quien entre. Nuestra página
personalizada publica las direcciones internas 192.168.50.2 y 192.168.50.3, los nombres
de las máquinas y la versión de Apache. Es información parecida a la que protegimos en
la primera parte cuando cerramos la transferencia de zona con TSIG, solo que aquí la
estamos entregando escrita en una página.

### Ausencia de autenticación

Ningún archivo del sitio pide usuario ni contraseña, así que quien tenga la dirección
puede descargarlo todo. Y la dirección no es un secreto: cuando enviamos el enlace por
WhatsApp para probarlo desde el celular, el registro de Apache mostró que WhatsApp entró
al servidor por su cuenta antes que nosotros, para generar la vista previa del enlace.

```
"GET / HTTP/1.1" 206 3195 "-" "WhatsApp/2.23.20.0"
```

Nadie hizo clic en nada. Basta con que la URL pase por una aplicación para que un
tercero acceda.

A eso se suma que perdemos el rastro de quién entra. Como `cloudflared` se conecta a
`localhost`, Apache anota todas las peticiones como si vinieran de 127.0.0.1. En el
registro aparece el navegador del visitante, pero no su dirección real.

### Un ataque concreto que permite este acceso

Las mediciones de la segunda parte dejan ver un problema. Con `BrotliCompressionQuality
11`, comprimir `datos.json` le cuesta al servidor 3.405 milisegundos de procesador por
cada petición. Como la máquina tiene un solo núcleo, eso significa que apenas alcanza a
atender unas 0,3 peticiones por segundo de ese archivo.

Alguien que pida ese recurso de forma repetida puede dejar el servidor sin capacidad de
respuesta, y a él le cuesta muy poco hacerlo: enviar la petición son unos 200 bytes. Es
el mismo desbalance que estudiamos en la primera parte con los ataques de amplificación
de DNS, donde una consulta pequeña genera una respuesta enorme.

### Límites del plan gratuito

Cloudflare advierte al arrancar el túnel que las conexiones sin cuenta no tienen
garantía de disponibilidad. En la práctica esto implica que el túnel puede caerse sin
aviso, que la dirección cambia cada vez que lo levantamos y que no hay forma de exigir
autenticación desde el propio servicio. Además todo el tráfico pasa por Cloudflare, que
descifra la conexión en sus servidores, así que para contenido sensible hay un
intermediario con acceso completo.

---

## Mitigaciones

### 1. Pedir usuario y contraseña

Es el mecanismo de directorio protegido que trabajamos en la práctica de HTTP, aplicado
ahora al sitio publicado.

```bash
sudo htpasswd -c /etc/apache2/.htpasswd sustentacion
```

```apache
<Directory /var/www/parcial>
    AuthType Basic
    AuthName "Parcial 1 - Servicios Telematicos"
    AuthUserFile /etc/apache2/.htpasswd
    Require valid-user
</Directory>
```

Con esto, conocer la dirección deja de ser suficiente. Las credenciales viajan
codificadas en Base64, que no es cifrado, pero el túnel añade HTTPS entre el visitante y
Cloudflare, así que en este caso quedan protegidas en el trayecto.

### 2. Apagar el túnel al terminar

```bash
pkill cloudflared
```

Es la medida más sencilla y la más efectiva. Mientras el túnel no esté activo, la
dirección pública deja de existir y el servidor vuelve a ser accesible únicamente desde
la red privada. El enunciado lo pide de forma explícita: no dejar el túnel abierto más
allá de la prueba.

### 3. Limitar cuántas peticiones se atienden

En la primera parte configuramos *rate limiting* en BIND para que el servidor DNS no
respondiera indefinidamente al mismo origen. La misma idea se puede aplicar en Apache
con `mod_evasive`, y sirve directamente contra el ataque descrito arriba.

```apache
<IfModule mod_evasive20.c>
    DOSPageCount      5
    DOSPageInterval   1
    DOSBlockingPeriod 60
</IfModule>
```

Conviene además bajar Brotli a calidad 5 mientras el servidor esté publicado. Según
nuestras propias mediciones, el costo por petición pasa de 3.405 a 21 milisegundos y el
archivo resultante solo crece un 0,1 %.

---

## Sobre restringir por dirección IP

El enunciado propone también restringir el acceso por IP, pero con este montaje no
funciona de forma directa. Como `cloudflared` se conecta a `localhost`, Apache ve todas
las peticiones como si vinieran de 127.0.0.1, así que una regla de este tipo bloquearía
a todos o a ninguno.

Para que sirviera habría que recuperar la dirección real usando `mod_remoteip` y la
cabecera `CF-Connecting-IP` que añade Cloudflare. Eso solo es confiable si se garantiza
que el servidor no es alcanzable por otra vía, porque una cabecera HTTP se puede
falsificar.
