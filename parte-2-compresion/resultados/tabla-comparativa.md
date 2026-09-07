# Tabla comparativa de compresion — Parte 2

**Parcial 1 · Servicios Telematicos · UAO**

## Metodologia

- Servidor: Apache 2.4.52 sobre `maestro` (192.168.50.3), 2 GB RAM, 1 vCPU.
- Dominio `parcial.empresa.local`, resuelto por el DNS esclavo de la Parte 1.
- **20 peticiones por medicion en una unica invocacion de curl**, sobre la
  misma conexion TCP. Se descarta la primera para excluir la resolucion DNS
  y el saludo TCP, que no forman parte del costo de compresion.
- **t_servidor** = `time_starttransfer - time_pretransfer`: intervalo entre
  terminar de enviar la peticion y recibir el primer byte. Ahi ocurre la
  compresion, asi que aisla el costo de CPU del resto de la latencia.
- **tx_10mbps**: tiempo teorico de transmision sobre un enlace de
  10 Mbps. La medicion es local (cliente y servidor en la misma
  maquina), asi que el ahorro de ancho de banda no aparece en los tiempos
  medidos; este calculo lo hace visible.
- Ratio = comprimido / original (menor es mejor) · Ahorro % = (1 - ratio) × 100

## `index.html` — HTML

Tamano original: **438093 bytes**

| Algoritmo / nivel | Tamano (B) | Ratio | Ahorro % | t servidor (ms) | t total (ms) | Transmision @ 10 Mbps (ms) |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| Sin comprimir (base) | 438093 | 1.000 | 0.0 % | 0.320 | 0.582 | 350.5 |
| gzip nivel 1 | 12293 | 0.028 | 97.2 % | 1.839 | 1.918 | 9.8 |
| gzip nivel 6 | 12779 | 0.029 | 97.1 % | 3.373 | 3.456 | 10.2 |
| gzip nivel 9 | 12647 | 0.029 | 97.1 % | 3.702 | 3.779 | 10.1 |
| brotli calidad 5 | 5643 | 0.013 | 98.7 % | 4.226 | 4.326 | 4.5 |
| brotli calidad 11 | 4646 | 0.011 | 98.9 % | 1451.559 | 1451.674 | 3.7 |

## `estilos.css` — CSS sin minificar

Tamano original: **268893 bytes**

| Algoritmo / nivel | Tamano (B) | Ratio | Ahorro % | t servidor (ms) | t total (ms) | Transmision @ 10 Mbps (ms) |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| Sin comprimir (base) | 268893 | 1.000 | 0.0 % | 0.025 | 0.377 | 215.1 |
| gzip nivel 1 | 4949 | 0.018 | 98.2 % | 1.116 | 1.186 | 4.0 |
| gzip nivel 6 | 4762 | 0.018 | 98.2 % | 1.991 | 2.060 | 3.8 |
| gzip nivel 9 | 4704 | 0.017 | 98.3 % | 2.244 | 2.316 | 3.8 |
| brotli calidad 5 | 2394 | 0.009 | 99.1 % | 3.133 | 3.224 | 1.9 |
| brotli calidad 11 | 2269 | 0.008 | 99.2 % | 711.766 | 711.872 | 1.8 |

## `estilos.min.css` — CSS minificado

Tamano original: **219393 bytes**

| Algoritmo / nivel | Tamano (B) | Ratio | Ahorro % | t servidor (ms) | t total (ms) | Transmision @ 10 Mbps (ms) |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| Sin comprimir (base) | 219393 | 1.000 | 0.0 % | 0.018 | 0.336 | 175.5 |
| gzip nivel 1 | 4754 | 0.022 | 97.8 % | 0.986 | 1.055 | 3.8 |
| gzip nivel 6 | 4583 | 0.021 | 97.9 % | 1.727 | 1.796 | 3.7 |
| gzip nivel 9 | 4527 | 0.021 | 97.9 % | 1.873 | 1.939 | 3.6 |
| brotli calidad 5 | 2384 | 0.011 | 98.9 % | 2.621 | 2.714 | 1.9 |
| brotli calidad 11 | 2134 | 0.010 | 99.0 % | 633.002 | 633.117 | 1.7 |

## `app.js` — JavaScript (jQuery real)

Tamano original: **285314 bytes**

| Algoritmo / nivel | Tamano (B) | Ratio | Ahorro % | t servidor (ms) | t total (ms) | Transmision @ 10 Mbps (ms) |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| Sin comprimir (base) | 285314 | 1.000 | 0.0 % | 0.052 | 0.457 | 228.3 |
| gzip nivel 1 | 102649 | 0.360 | 64.0 % | 3.589 | 6.143 | 82.1 |
| gzip nivel 6 | 84014 | 0.294 | 70.6 % | 10.084 | 14.574 | 67.2 |
| gzip nivel 9 | 83592 | 0.293 | 70.7 % | 16.878 | 24.662 | 66.9 |
| brotli calidad 5 | 79680 | 0.279 | 72.1 % | 10.464 | 10.672 | 63.7 |
| brotli calidad 11 | 69545 | 0.244 | 75.6 % | 490.223 | 490.416 | 55.6 |

## `datos.json` — JSON

Tamano original: **1348682 bytes**

| Algoritmo / nivel | Tamano (B) | Ratio | Ahorro % | t servidor (ms) | t total (ms) | Transmision @ 10 Mbps (ms) |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| Sin comprimir (base) | 1348682 | 1.000 | 0.0 % | 0.437 | 1.176 | 1078.9 |
| gzip nivel 1 | 68289 | 0.051 | 94.9 % | 5.085 | 6.305 | 54.6 |
| gzip nivel 6 | 68879 | 0.051 | 94.9 % | 8.054 | 11.455 | 55.1 |
| gzip nivel 9 | 68366 | 0.051 | 94.9 % | 18.914 | 27.192 | 54.7 |
| brotli calidad 5 | 25315 | 0.019 | 98.1 % | 20.840 | 20.990 | 20.3 |
| brotli calidad 11 | 23745 | 0.018 | 98.2 % | 3405.139 | 3405.272 | 19.0 |

## `grafico.svg` — SVG

Tamano original: **338798 bytes**

| Algoritmo / nivel | Tamano (B) | Ratio | Ahorro % | t servidor (ms) | t total (ms) | Transmision @ 10 Mbps (ms) |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| Sin comprimir (base) | 338798 | 1.000 | 0.0 % | 0.202 | 0.482 | 271.0 |
| gzip nivel 1 | 24749 | 0.073 | 92.7 % | 2.397 | 2.482 | 19.8 |
| gzip nivel 6 | 20666 | 0.061 | 93.9 % | 4.135 | 4.212 | 16.5 |
| gzip nivel 9 | 19498 | 0.058 | 94.2 % | 13.676 | 13.772 | 15.6 |
| brotli calidad 5 | 20771 | 0.061 | 93.9 % | 4.826 | 4.924 | 16.6 |
| brotli calidad 11 | 16022 | 0.047 | 95.3 % | 608.785 | 608.905 | 12.8 |

## `feed.xml` — XML

Tamano original: **772806 bytes**

| Algoritmo / nivel | Tamano (B) | Ratio | Ahorro % | t servidor (ms) | t total (ms) | Transmision @ 10 Mbps (ms) |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| Sin comprimir (base) | 772806 | 1.000 | 0.0 % | 0.192 | 0.719 | 618.2 |
| gzip nivel 1 | 37050 | 0.048 | 95.2 % | 3.595 | 3.734 | 29.6 |
| gzip nivel 6 | 35662 | 0.046 | 95.4 % | 9.360 | 9.540 | 28.5 |
| gzip nivel 9 | 35390 | 0.046 | 95.4 % | 8.428 | 8.536 | 28.3 |
| brotli calidad 5 | 13851 | 0.018 | 98.2 % | 8.060 | 8.160 | 11.1 |
| brotli calidad 11 | 15702 | 0.020 | 98.0 % | 1534.392 | 1534.504 | 12.6 |

## `lorem.txt` — Texto plano

Tamano original: **1340000 bytes**

| Algoritmo / nivel | Tamano (B) | Ratio | Ahorro % | t servidor (ms) | t total (ms) | Transmision @ 10 Mbps (ms) |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| Sin comprimir (base) | 1340000 | 1.000 | 0.0 % | 0.451 | 1.237 | 1072.0 |
| gzip nivel 1 | 12452 | 0.009 | 99.1 % | 4.748 | 4.835 | 10.0 |
| gzip nivel 6 | 6109 | 0.005 | 99.5 % | 11.385 | 11.483 | 4.9 |
| gzip nivel 9 | 6109 | 0.005 | 99.5 % | 9.207 | 9.304 | 4.9 |
| brotli calidad 5 | 273 | 0.000 | 100.0 % | 3.580 | 3.677 | 0.2 |
| brotli calidad 11 | 222 | 0.000 | 100.0 % | 27.249 | 27.353 | 0.2 |

## `foto.jpg` — Imagen JPEG

Tamano original: **133564 bytes**

| Algoritmo / nivel | Tamano (B) | Ratio | Ahorro % | t servidor (ms) | t total (ms) | Transmision @ 10 Mbps (ms) |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| Sin comprimir (base) | 133564 | 1.000 | 0.0 % | 0.020 | 0.278 | 106.9 |
| gzip nivel 1 | 133564 | 1.000 | 0.0 % | 0.024 | 0.391 | 106.9 |
| gzip nivel 6 | 133564 | 1.000 | 0.0 % | 0.023 | 0.365 | 106.9 |
| gzip nivel 9 | 133564 | 1.000 | 0.0 % | 0.019 | 0.291 | 106.9 |
| brotli calidad 5 | 133564 | 1.000 | 0.0 % | 0.022 | 0.364 | 106.9 |
| brotli calidad 11 | 133564 | 1.000 | 0.0 % | 0.018 | 0.277 | 106.9 |

## `imagen.png` — Imagen PNG

Tamano original: **2554638 bytes**

| Algoritmo / nivel | Tamano (B) | Ratio | Ahorro % | t servidor (ms) | t total (ms) | Transmision @ 10 Mbps (ms) |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| Sin comprimir (base) | 2554638 | 1.000 | 0.0 % | 0.405 | 2.116 | 2043.7 |
| gzip nivel 1 | 2554638 | 1.000 | 0.0 % | 0.596 | 2.277 | 2043.7 |
| gzip nivel 6 | 2554638 | 1.000 | 0.0 % | 0.353 | 2.071 | 2043.7 |
| gzip nivel 9 | 2554638 | 1.000 | 0.0 % | 0.372 | 2.397 | 2043.7 |
| brotli calidad 5 | 2554638 | 1.000 | 0.0 % | 0.522 | 2.043 | 2043.7 |
| brotli calidad 11 | 2554638 | 1.000 | 0.0 % | 0.435 | 2.135 | 2043.7 |

## `clip.mp4` — Video MP4

Tamano original: **2848208 bytes**

| Algoritmo / nivel | Tamano (B) | Ratio | Ahorro % | t servidor (ms) | t total (ms) | Transmision @ 10 Mbps (ms) |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| Sin comprimir (base) | 2848208 | 1.000 | 0.0 % | 0.440 | 2.274 | 2278.6 |
| gzip nivel 1 | 2848208 | 1.000 | 0.0 % | 0.455 | 2.176 | 2278.6 |
| gzip nivel 6 | 2848208 | 1.000 | 0.0 % | 0.531 | 2.442 | 2278.6 |
| gzip nivel 9 | 2848208 | 1.000 | 0.0 % | 0.522 | 2.442 | 2278.6 |
| brotli calidad 5 | 2848208 | 1.000 | 0.0 % | 0.589 | 3.387 | 2278.6 |
| brotli calidad 11 | 2848208 | 1.000 | 0.0 % | 0.442 | 2.334 | 2278.6 |

## `paquete.zip` — Archivo ZIP

Tamano original: **122892 bytes**

| Algoritmo / nivel | Tamano (B) | Ratio | Ahorro % | t servidor (ms) | t total (ms) | Transmision @ 10 Mbps (ms) |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| Sin comprimir (base) | 122892 | 1.000 | 0.0 % | 0.272 | 0.486 | 98.3 |
| gzip nivel 1 | 122892 | 1.000 | 0.0 % | 0.017 | 0.293 | 98.3 |
| gzip nivel 6 | 122892 | 1.000 | 0.0 % | 0.020 | 0.294 | 98.3 |
| gzip nivel 9 | 122892 | 1.000 | 0.0 % | 0.024 | 0.311 | 98.3 |
| brotli calidad 5 | 122892 | 1.000 | 0.0 % | 0.063 | 0.401 | 98.3 |
| brotli calidad 11 | 122892 | 1.000 | 0.0 % | 0.016 | 0.286 | 98.3 |

