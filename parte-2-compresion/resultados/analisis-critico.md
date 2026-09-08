# Análisis crítico — Parte 2

**Configuración, comparación y evaluación de la compresión en Apache**
Parcial 1 · Servicios Telemáticos · Universidad Autónoma de Occidente

---

## Metodología de medición

| Elemento | Detalle |
| :--- | :--- |
| Servidor | Apache 2.4.52 (Ubuntu 22.04) sobre `maestro`, 2 GB RAM, 1 vCPU |
| Dominio | `parcial.empresa.local`, resuelto por el DNS esclavo de la Parte 1 |
| Cliente de medición | `curl` 7.81 local |
| Repeticiones | 20 peticiones por combinación, sobre una única conexión TCP reutilizada |
| Tiempo / CPU | `time_starttransfer − time_pretransfer`: intervalo entre terminar de enviar la petición y recibir el primer byte. Ahí ocurre la compresión, por lo que aísla el costo de CPU del servidor |
| Transmisión | Tiempo teórico sobre un enlace de 10 Mbps: `bytes × 8 / 10.000.000` |
| Ratio | comprimido / original (menor es mejor) |
| Ahorro % | `(1 − ratio) × 100` |

> **Nota metodológica.** La medición es local: cliente y servidor están en la misma
> máquina, sin red física de por medio. Por eso el tiempo *total* de las respuestas
> comprimidas es mayor que el de las no comprimidas — se paga el costo de CPU sin
> obtener el beneficio de transmisión. La columna de transmisión estimada hace
> visible ese beneficio, que en una red real es el que domina.

---

## Tabla comparativa de resultados

### HTML

**Recurso evaluado:** `index.html` · **Tamaño original:** 438.093 bytes

| Algoritmo / nivel | Tamaño (B) | Ratio | Ahorro % | Tiempo / CPU (ms) | Transmisión @10 Mbps (ms) |
| :--- | ---: | ---: | ---: | ---: | ---: |
| Sin comprimir (base) | 438.093 | 1,000 | 0,0 % | 0,320 | 350,5 |
| gzip nivel 1 | 12.293 | 0,028 | 97,2 % | 1,839 | 9,8 |
| gzip nivel 6 | 12.779 | 0,029 | 97,1 % | 3,373 | 10,2 |
| gzip nivel 9 | 12.647 | 0,029 | 97,1 % | 3,702 | 10,1 |
| brotli calidad 5 | 5.643 | 0,013 | 98,7 % | 4,226 | 4,5 |
| brotli calidad 11 | 4.646 | 0,011 | 98,9 % | **1.451,559** | 3,7 |

### CSS sin minificar

**Recurso evaluado:** `estilos.css` · **Tamaño original:** 268.893 bytes

| Algoritmo / nivel | Tamaño (B) | Ratio | Ahorro % | Tiempo / CPU (ms) | Transmisión @10 Mbps (ms) |
| :--- | ---: | ---: | ---: | ---: | ---: |
| Sin comprimir (base) | 268.893 | 1,000 | 0,0 % | 0,025 | 215,1 |
| gzip nivel 1 | 4.949 | 0,018 | 98,2 % | 1,116 | 4,0 |
| gzip nivel 6 | 4.762 | 0,018 | 98,2 % | 1,991 | 3,8 |
| gzip nivel 9 | 4.704 | 0,017 | 98,3 % | 2,244 | 3,8 |
| brotli calidad 5 | 2.394 | 0,009 | 99,1 % | 3,133 | 1,9 |
| brotli calidad 11 | 2.269 | 0,008 | 99,2 % | **711,766** | 1,8 |

### CSS minificado

**Recurso evaluado:** `estilos.min.css` · **Tamaño original:** 219.393 bytes

| Algoritmo / nivel | Tamaño (B) | Ratio | Ahorro % | Tiempo / CPU (ms) | Transmisión @10 Mbps (ms) |
| :--- | ---: | ---: | ---: | ---: | ---: |
| Sin comprimir (base) | 219.393 | 1,000 | 0,0 % | 0,018 | 175,5 |
| gzip nivel 1 | 4.754 | 0,022 | 97,8 % | 0,986 | 3,8 |
| gzip nivel 6 | 4.583 | 0,021 | 97,9 % | 1,727 | 3,7 |
| gzip nivel 9 | 4.527 | 0,021 | 97,9 % | 1,873 | 3,6 |
| brotli calidad 5 | 2.384 | 0,011 | 98,9 % | 2,621 | 1,9 |
| brotli calidad 11 | 2.134 | 0,010 | 99,0 % | **633,002** | 1,7 |

### JavaScript (biblioteca real: jQuery 3.7.1 sin minificar)

**Recurso evaluado:** `app.js` · **Tamaño original:** 285.314 bytes

| Algoritmo / nivel | Tamaño (B) | Ratio | Ahorro % | Tiempo / CPU (ms) | Transmisión @10 Mbps (ms) |
| :--- | ---: | ---: | ---: | ---: | ---: |
| Sin comprimir (base) | 285.314 | 1,000 | 0,0 % | 0,052 | 228,3 |
| gzip nivel 1 | 102.649 | 0,360 | 64,0 % | 3,589 | 82,1 |
| gzip nivel 6 | 84.014 | 0,294 | 70,6 % | 10,084 | 67,2 |
| gzip nivel 9 | 83.592 | 0,293 | 70,7 % | 16,878 | 66,9 |
| brotli calidad 5 | 79.680 | 0,279 | 72,1 % | 10,464 | 63,7 |
| brotli calidad 11 | 69.545 | 0,244 | 75,6 % | **490,223** | 55,6 |

### JSON (dataset de 8.000 registros)

**Recurso evaluado:** `datos.json` · **Tamaño original:** 1.348.682 bytes

| Algoritmo / nivel | Tamaño (B) | Ratio | Ahorro % | Tiempo / CPU (ms) | Transmisión @10 Mbps (ms) |
| :--- | ---: | ---: | ---: | ---: | ---: |
| Sin comprimir (base) | 1.348.682 | 1,000 | 0,0 % | 0,437 | 1.078,9 |
| gzip nivel 1 | 68.289 | 0,051 | 94,9 % | 5,085 | 54,6 |
| gzip nivel 6 | 68.879 | 0,051 | 94,9 % | 8,054 | 55,1 |
| gzip nivel 9 | 68.366 | 0,051 | 94,9 % | 18,914 | 54,7 |
| brotli calidad 5 | 25.315 | 0,019 | 98,1 % | 20,840 | 20,3 |
| brotli calidad 11 | 23.745 | 0,018 | 98,2 % | **3.405,139** | 19,0 |

### SVG

**Recurso evaluado:** `grafico.svg` · **Tamaño original:** 338.798 bytes

| Algoritmo / nivel | Tamaño (B) | Ratio | Ahorro % | Tiempo / CPU (ms) | Transmisión @10 Mbps (ms) |
| :--- | ---: | ---: | ---: | ---: | ---: |
| Sin comprimir (base) | 338.798 | 1,000 | 0,0 % | 0,202 | 271,0 |
| gzip nivel 1 | 24.749 | 0,073 | 92,7 % | 2,397 | 19,8 |
| gzip nivel 6 | 20.666 | 0,061 | 93,9 % | 4,135 | 16,5 |
| gzip nivel 9 | 19.498 | 0,058 | 94,2 % | 13,676 | 15,6 |
| brotli calidad 5 | 20.771 | 0,061 | 93,9 % | 4,826 | 16,6 |
| brotli calidad 11 | 16.022 | 0,047 | 95,3 % | **608,785** | 12,8 |

### XML

**Recurso evaluado:** `feed.xml` · **Tamaño original:** 772.806 bytes

| Algoritmo / nivel | Tamaño (B) | Ratio | Ahorro % | Tiempo / CPU (ms) | Transmisión @10 Mbps (ms) |
| :--- | ---: | ---: | ---: | ---: | ---: |
| Sin comprimir (base) | 772.806 | 1,000 | 0,0 % | 0,192 | 618,2 |
| gzip nivel 1 | 37.050 | 0,048 | 95,2 % | 3,595 | 29,6 |
| gzip nivel 6 | 35.662 | 0,046 | 95,4 % | 9,360 | 28,5 |
| gzip nivel 9 | 35.390 | 0,046 | 95,4 % | 8,428 | 28,3 |
| brotli calidad 5 | **13.851** | 0,018 | 98,2 % | 8,060 | 11,1 |
| brotli calidad 11 | 15.702 | 0,020 | 98,0 % | **1.534,392** | 12,6 |

> ⚠️ Caso anómalo: brotli calidad 11 produce un archivo **más grande** que calidad 5.
> Ver punto 8.

### Texto plano

**Recurso evaluado:** `lorem.txt` · **Tamaño original:** 1.340.000 bytes

| Algoritmo / nivel | Tamaño (B) | Ratio | Ahorro % | Tiempo / CPU (ms) | Transmisión @10 Mbps (ms) |
| :--- | ---: | ---: | ---: | ---: | ---: |
| Sin comprimir (base) | 1.340.000 | 1,000 | 0,0 % | 0,451 | 1.072,0 |
| gzip nivel 1 | 12.452 | 0,009 | 99,1 % | 4,748 | 10,0 |
| gzip nivel 6 | 6.109 | 0,005 | 99,5 % | 11,385 | 4,9 |
| gzip nivel 9 | 6.109 | 0,005 | 99,5 % | 9,207 | 4,9 |
| brotli calidad 5 | 273 | 0,000 | 100,0 % | 3,580 | 0,2 |
| brotli calidad 11 | **222** | 0,000 | 100,0 % | 27,249 | 0,2 |

### Recursos binarios ya comprimidos (excluidos)

| Recurso | Tamaño original (B) | Tamaño con cualquier algoritmo (B) | Ratio | Ahorro % | Tiempo / CPU (ms) |
| :--- | ---: | ---: | ---: | ---: | ---: |
| `foto.jpg` (JPEG) | 133.564 | 133.564 | 1,000 | 0,0 % | 0,018 – 0,024 |
| `imagen.png` (PNG) | 2.554.638 | 2.554.638 | 1,000 | 0,0 % | 0,353 – 0,596 |
| `clip.mp4` (vídeo) | 2.848.208 | 2.848.208 | 1,000 | 0,0 % | 0,440 – 0,589 |
| `paquete.zip` (ZIP) | 122.892 | 122.892 | 1,000 | 0,0 % | 0,016 – 0,063 |

---

## 7. Brotli vs gzip

**¿Cuánto mejora Brotli el ratio frente a gzip sobre texto? ¿En qué tipos de archivo la diferencia es significativa y en cuáles es marginal?**

Comparando el mejor resultado de cada algoritmo (gzip nivel 9 frente a brotli calidad 11):

| Recurso | gzip 9 (B) | brotli 11 (B) | Factor | Reducción adicional |
| :--- | ---: | ---: | ---: | ---: |
| `lorem.txt` | 6.109 | 222 | **27,52×** | 96,4 % |
| `datos.json` | 68.366 | 23.745 | **2,88×** | 65,3 % |
| `index.html` | 12.647 | 4.646 | **2,72×** | 63,3 % |
| `feed.xml` | 35.390 | 15.702 | **2,25×** | 55,6 % |
| `estilos.css` | 4.704 | 2.269 | **2,07×** | 51,8 % |
| `grafico.svg` | 19.498 | 16.022 | **1,22×** | 17,8 % |
| `app.js` (jQuery) | 83.592 | 69.545 | **1,20×** | 16,8 % |

**La ventaja de Brotli no es uniforme: varía entre 1,2× y 27,5× según el contenido.**

**Diferencia significativa** en texto plano, JSON, HTML, XML y CSS (factores de 2,1× a 27,5×).
Estos formatos comparten dos características que Brotli explota:

1. **Vocabulario predecible.** Brotli incorpora un diccionario preentrenado de unas
   13.000 palabras y fragmentos frecuentes en la web (`<!DOCTYPE html>`, `function`,
   `background-color`, `"nombre":`). Puede referenciarlos sin transmitirlos.
2. **Repeticiones a larga distancia.** La ventana de gzip es de 32 KB; la de Brotli,
   hasta 16 MB. En `datos.json` (1,3 MB) o `lorem.txt` (1,34 MB), gzip pierde de vista
   patrones que Brotli sigue encontrando.

**Diferencia marginal** en JavaScript real (16,8 %) y SVG (17,8 %). El motivo es el
contrario: `app.js` es jQuery, código con nombres de variables y lógica propios que no
están en ningún diccionario; `grafico.svg` contiene 4.000 coordenadas generadas al azar,
donde no hay estructura que un diccionario pueda anticipar.

> **Conclusión.** `app.js` es el dato más representativo de un sitio real: **Brotli mejora
> un 17 %, no un 60 %.** Las cifras espectaculares de los otros recursos provienen de
> contenido sintético con alta redundancia. Al dimensionar una decisión de producción,
> la referencia honesta es el 17 %.

---

## 8. Niveles de compresión

**¿Qué gana en tamaño al pasar de nivel 1 → 6 → 9 (gzip) y 5 → 11 (brotli)? ¿Justifica ese ahorro adicional el mayor costo de CPU/latencia? Identifique el punto de rendimientos decrecientes.**

### gzip: de nivel 1 a nivel 6

| Recurso | nivel 1 (B) | nivel 6 (B) | Variación |
| :--- | ---: | ---: | ---: |
| `lorem.txt` | 12.452 | 6.109 | **−50,9 %** |
| `app.js` | 102.649 | 84.014 | **−18,2 %** |
| `grafico.svg` | 24.749 | 20.666 | −16,5 % |
| `estilos.css` | 4.949 | 4.762 | −3,8 % |
| `feed.xml` | 37.050 | 35.662 | −3,7 % |
| `datos.json` | 68.289 | 68.879 | **+0,9 %** |
| `index.html` | 12.293 | 12.779 | **+4,0 %** |

El salto de 1 a 6 es rentable en la mayoría de los casos: hasta un 51 % menos por un
costo de CPU que se duplica pero sigue en el orden de milisegundos.

Dos recursos empeoran ligeramente. No es un error de medición: se reprodujo en tres
ejecuciones independientes. En contenido con repeticiones muy largas y muy cercanas,
la búsqueda exhaustiva del nivel 6 puede segmentar los bloques Huffman de forma menos
óptima que la heurística rápida del nivel 1.

### gzip: de nivel 6 a nivel 9

| Recurso | nivel 6 (B) | nivel 9 (B) | Variación | CPU 6 → 9 |
| :--- | ---: | ---: | ---: | :--- |
| `grafico.svg` | 20.666 | 19.498 | −5,7 % | 4,14 → 13,68 ms (**+231 %**) |
| `estilos.css` | 4.762 | 4.704 | −1,2 % | 1,99 → 2,24 ms (+13 %) |
| `feed.xml` | 35.662 | 35.390 | −0,8 % | 9,36 → 8,43 ms (−10 %) |
| `app.js` | 84.014 | 83.592 | **−0,5 %** | 10,08 → 16,88 ms (**+67 %**) |
| `lorem.txt` | 6.109 | 6.109 | **0,0 %** | 11,39 → 9,21 ms |

> **Punto de rendimientos decrecientes de gzip: nivel 6.**
> El paso de 6 a 9 reduce el tamaño entre un 0 % y un 5,7 %, mientras el costo de CPU
> sube hasta un 231 %. En `app.js`, el caso más representativo, se pagan **6,8 ms
> adicionales por cada petición** para ahorrar **422 bytes**. Sobre un enlace de 10 Mbps
> esos 422 bytes se transmiten en 0,3 ms: **el servidor gasta 22 veces más tiempo del
> que el cliente ahorra.**

### Brotli: de calidad 5 a calidad 11

| Recurso | calidad 5 (B) | calidad 11 (B) | Variación | CPU 5 → 11 | Factor |
| :--- | ---: | ---: | ---: | :--- | ---: |
| `index.html` | 5.643 | 4.646 | −17,7 % | 4,23 → 1.451,56 ms | **×343** |
| `app.js` | 79.680 | 69.545 | −12,7 % | 10,46 → 490,22 ms | **×47** |
| `datos.json` | 25.315 | 23.745 | −6,2 % | 20,84 → 3.405,14 ms | **×163** |
| `estilos.css` | 2.394 | 2.269 | −5,2 % | 3,13 → 711,77 ms | **×227** |
| `lorem.txt` | 273 | 222 | −18,7 % | 3,58 → 27,25 ms | ×8 |
| `feed.xml` | 13.851 | **15.702** | **+13,4 %** | 8,06 → 1.534,39 ms | ×190 |

> **Punto de rendimientos decrecientes de Brotli: calidad 5.**
> Calidad 11 cuesta entre **47 y 343 veces más CPU** para reducir el tamaño entre un
> 5 % y un 19 %. El caso extremo es `datos.json`: **3,4 segundos de CPU** para ahorrar
> **1.570 bytes** sobre un archivo de 1,3 MB (0,1 %).

**Caso anómalo — `feed.xml`.** Calidad 11 produce un archivo **1.851 bytes más grande**
que calidad 5, gastando 190 veces más CPU. El resultado se reprodujo en tres
ejecuciones. Brotli 11 activa modelado de contexto y estrategias de partición de ventana
que no se usan en calidad 5; sobre contenido extremadamente uniforme, esa maquinaria
adicional puede elegir una segmentación peor. Es una demostración concreta de que
**más esfuerzo computacional no garantiza mejor resultado.**

---

## 9. Tipos de archivo

**¿Por qué los recursos ya comprimidos (JPEG, PNG, MP4, ZIP) no se benefician —o incluso crecen— al comprimirlos? Sustente con sus datos.**

Los cuatro recursos binarios devolvieron **ratio 1,000 y ahorro 0,0 %** en las seis
combinaciones evaluadas. Además, su **tiempo de servidor no varió** respecto a la línea
base (0,018 ms sin comprimir frente a 0,018 – 0,024 ms con la cabecera `Accept-Encoding`
activa): Apache **ni siquiera intentó** comprimirlos, gracias a la regla de exclusión.

### Por qué no se benefician

Un compresor sin pérdida funciona **detectando y eliminando redundancia**. Los cuatro
formatos ya pasaron por ese proceso:

| Formato | Compresión que ya aplica internamente |
| :--- | :--- |
| **JPEG** | Transformada DCT + cuantización + codificación Huffman. Compresión **con pérdida**: ya descartó información que el ojo no percibe |
| **PNG** | Filtrado por líneas + **DEFLATE**, literalmente el mismo algoritmo que gzip |
| **MP4** (H.264) | Predicción entre cuadros + transformada + codificación entrópica |
| **ZIP** | **DEFLATE** aplicado a cada entrada del archivo |

Tras esa primera pasada, la salida se aproxima estadísticamente a datos aleatorios: no
quedan secuencias repetidas que LZ77 pueda referenciar ni sesgos de frecuencia que
Huffman pueda explotar. **Comprimir un PNG con gzip es aplicarle DEFLATE por segunda
vez** — el equivalente a pasar la aspiradora a una bolsa a la que ya se le extrajo el aire.

### Por qué pueden crecer

El formato gzip añade siempre una cabecera de 10 bytes, un CRC-32 de 4 bytes y el tamaño
original en otros 4, más las marcas de bloque de DEFLATE. Si el algoritmo no encuentra
redundancia que eliminar, esos bytes son **pérdida neta**: el archivo sale mayor que el
original.

Esto no es una limitación de gzip sino un resultado general, consecuencia del **principio
del palomar**: no existe un algoritmo que comprima todas las entradas posibles. Si
existiera, aplicándolo repetidamente se podría reducir cualquier archivo a un solo bit.
Todo compresor que reduce un subconjunto de entradas **necesariamente agranda otro**.

### Consecuencia práctica

Comprimir binarios ya comprimidos tiene **costo positivo y beneficio nulo o negativo**:
consume CPU del servidor, aumenta la latencia y puede incrementar los bytes transmitidos.
Por eso la configuración excluye explícitamente esas extensiones:

```apache
SetEnvIfNoCase Request_URI \.(?:gif|jpe?g|png|webp|mp4|avi|zip|gz|pdf)$ \
    no-gzip dont-vary
```

La bandera `dont-vary` complementa la exclusión: al no existir variantes según la
codificación, se omite la cabecera `Vary`, lo que permite a las cachés intermedias
almacenar una sola copia del recurso en lugar de una por cada valor de `Accept-Encoding`.

---

## 10. Impacto en CPU y ancho de banda

**Discuta el equilibrio entre ahorro de ancho de banda y consumo de CPU del servidor, y cómo cambia bajo concurrencia alta.**

### El balance en una petición

Tomando `app.js` (jQuery real) sobre un enlace de 10 Mbps:

| Configuración | Bytes | CPU servidor | Transmisión | **Tiempo total** |
| :--- | ---: | ---: | ---: | ---: |
| Sin comprimir | 285.314 | 0,05 ms | 228,3 ms | **228,4 ms** |
| gzip nivel 6 | 84.014 | 10,08 ms | 67,2 ms | **77,3 ms** |
| **brotli calidad 5** | 79.680 | 10,46 ms | 63,7 ms | **74,2 ms** |
| brotli calidad 11 | 69.545 | 490,22 ms | 55,6 ms | **545,8 ms** |

Tres conclusiones:

1. **Comprimir es rentable:** de 228 ms a 74 ms, una mejora de 3,1×.
2. **Brotli calidad 5 es el óptimo al vuelo:** el mejor tiempo total, con un costo de CPU
   equivalente al de gzip 6.
3. **Brotli calidad 11 es peor que no comprimir** (546 ms frente a 228 ms). El ahorro de
   10 KB en transmisión no compensa 490 ms de CPU.

### Cómo cambia el punto de equilibrio con el ancho de banda

El beneficio de comprimir depende de la velocidad del enlace. Para `app.js`:

| Enlace | Sin comprimir | brotli 5 | brotli 11 | Mejor opción |
| :--- | ---: | ---: | ---: | :--- |
| Localhost (~1 Gbps) | 2,3 ms | 11,1 ms | 496 ms | **Sin comprimir** |
| 100 Mbps | 22,8 ms | 16,9 ms | 496 ms | brotli 5 |
| 10 Mbps | 228,4 ms | 74,2 ms | 546 ms | **brotli 5** |
| 1 Mbps | 2.282 ms | 648 ms | 1.046 ms | **brotli 5** |
| 256 kbps (móvil malo) | 8.916 ms | 2.500 ms | 2.664 ms | **brotli 5** |

**La compresión intercambia tiempo de CPU por ancho de banda.** Cuanto más lento el
enlace, mejor el negocio. Esto explica por qué la medición local muestra tiempos totales
*mayores* con compresión: en localhost la red no es el cuello de botella, así que solo se
paga el costo sin obtener el beneficio.

### Bajo concurrencia alta

El servidor dispone de **1 vCPU**. La compresión es una operación de CPU, por lo que su
costo determina directamente el número máximo de peticiones por segundo:

| Configuración | CPU por petición (`datos.json`) | Peticiones/s teóricas |
| :--- | ---: | ---: |
| Sin comprimir | 0,44 ms | ~2.270 |
| gzip nivel 1 | 5,09 ms | ~196 |
| gzip nivel 6 | 8,05 ms | ~124 |
| gzip nivel 9 | 18,91 ms | ~53 |
| brotli calidad 5 | 20,84 ms | ~48 |
| brotli calidad 11 | 3.405,14 ms | **~0,3** |

Con brotli calidad 11 el servidor atendería **menos de una petición cada tres segundos**
para ese recurso. Diez clientes simultáneos generarían una cola creciente hasta agotar el
límite de conexiones de Apache.

**El riesgo se invierte bajo carga.** Con poca concurrencia, el cuello de botella es la
red y comprimir agresivamente parece buena idea. Con alta concurrencia, el cuello de
botella pasa a ser la CPU y la compresión agresiva se convierte en un **vector de
denegación de servicio**: un atacante que solicite repetidamente el recurso más grande
consume CPU del servidor a un costo trivial para él. Es la misma asimetría del ataque de
amplificación DNS que se mitigó en la Parte 1.

Un valor moderado (gzip 6 o brotli 5) sostiene entre 48 y 124 peticiones por segundo con
más del 94 % de ahorro en ancho de banda: **el 99 % del beneficio al 0,6 % del costo.**

---

## 11. Contenido estático vs dinámico

**Argumente cuándo conviene precomprimir en disco (brotli 11 servido con mod_headers) frente a comprimir al vuelo, y proponga una configuración recomendada para producción justificando algoritmo y nivel por tipo de contenido.**

### El criterio: cuántas veces se paga el costo

| | Compresión al vuelo | Precompresión en disco |
| :--- | :--- | :--- |
| Cuándo se comprime | En **cada** petición | **Una vez**, al desplegar |
| Costo de CPU | Se paga N veces | Se paga 1 vez |
| Nivel razonable | Moderado (gzip 6 / brotli 5) | Máximo (brotli 11) |
| Requisito | — | El contenido no cambia entre peticiones |
| Costo adicional | — | Almacenamiento: 2 o 3 copias por recurso |

Con los datos medidos, `index.html` servido 10.000 veces al día:

- **Al vuelo con brotli 11:** 10.000 × 1.451,56 ms = **4 horas de CPU diarias**
- **Precomprimido con brotli 11:** 1.451,56 ms **una vez**, y cada petición solo lee un
  archivo del disco (~0,32 ms). Se obtienen los 4.646 bytes al precio de servir un
  estático.

> **Regla.** La precompresión convierte un costo *por petición* en un costo *por
> despliegue*. Si el recurso es estático, la calidad máxima deja de tener contraindicación
> y pasa a ser la opción obvia. Si es dinámico —generado por PHP, una API, un panel de
> usuario— la respuesta es distinta en cada petición y no hay nada que precomprimir: solo
> queda comprimir al vuelo, con un nivel moderado.

### Implementación de la precompresión

```apache
<IfModule mod_headers.c>
    # Servir el .br precomprimido si el cliente acepta brotli
    RewriteCond %{HTTP:Accept-Encoding} br
    RewriteCond %{REQUEST_FILENAME}.br -f
    RewriteRule ^(.*)$ $1.br [QSA]

    <FilesMatch "\.br$">
        Header set Content-Encoding br
        Header append Vary Accept-Encoding
    </FilesMatch>
</IfModule>
```

Los archivos se generan al desplegar:

```bash
brotli -q 11 -k index.html app.js estilos.css datos.json
gzip  -9 -k index.html app.js estilos.css datos.json   # respaldo para clientes sin br
```

### Configuración recomendada para producción

| Tipo de contenido | Estrategia | Algoritmo y nivel | Justificación con los datos medidos |
| :--- | :--- | :--- | :--- |
| **Estáticos** (HTML, CSS, JS, SVG de la aplicación) | Precomprimir en disco | **brotli 11** + gzip 9 de respaldo | El costo se paga una vez al desplegar. `index.html` baja a 4.646 B (98,9 %) sin coste por petición |
| **API / JSON dinámico** | Al vuelo | **brotli 5** | 20,84 ms y 98,1 % de ahorro. Calidad 11 costaría 3.405 ms para ganar 0,1 % |
| **HTML generado** (plantillas, paneles) | Al vuelo | **brotli 5**, gzip 6 de respaldo | 4,23 ms por petición, 98,7 % de ahorro |
| **Respuestas muy pequeñas** (< 1 KB) | **No comprimir** | — | La cabecera gzip (18 B) más el costo fijo no se amortizan |
| **Binarios ya comprimidos** | **Excluir** | — | Ratio 1,000 medido en las cuatro categorías. Solo consume CPU |
| **Alta concurrencia sostenida** | Al vuelo | **gzip 6** | 124 peticiones/s con 94,9 % de ahorro. El más conservador en CPU |

### Configuración final adoptada en este parcial

```apache
# mod_deflate — respaldo para clientes que no aceptan Brotli
DeflateCompressionLevel 6

# mod_brotli — algoritmo preferido cuando el cliente lo acepta
BrotliCompressionQuality 11
BrotliCompressionWindow 22
```

> **Nota.** Se mantiene calidad 11 porque el sitio de prueba es **estático** y de bajo
> tráfico, condiciones bajo las cuales el costo de CPU no se manifiesta. En un servicio
> con concurrencia real, la recomendación sería **brotli 5 al vuelo** o **brotli 11
> precomprimido**, según la naturaleza de cada recurso.

---

## Anexo — Tiempo de transmisión y ancho de banda

### Ahorro agregado del sitio completo

Sumando los ocho recursos de texto (5.011.979 bytes sin comprimir):

| Configuración | Bytes totales | Ahorro | Transmisión @10 Mbps |
| :--- | ---: | ---: | ---: |
| Sin comprimir | 5.011.979 | — | **4.010 ms** |
| gzip nivel 6 | 237.454 | **95,26 %** | 190 ms |
| brotli calidad 11 | 134.285 | **97,32 %** | **107 ms** |

Una carga completa del sitio pasa de **4,0 segundos a 0,11 segundos** de transmisión.

### Impacto en costo de ancho de banda

Con 100.000 cargas mensuales del sitio:

| Configuración | Tráfico mensual | Reducción |
| :--- | ---: | ---: |
| Sin comprimir | 501,2 GB | — |
| gzip nivel 6 | 23,7 GB | −477,5 GB |
| brotli calidad 11 | 13,4 GB | **−487,8 GB** |

### Verificación independiente en Wireshark

La captura sobre la interfaz host-only (`192.168.50.1 ↔ 192.168.50.3`, filtro
`http && ip.addr == 192.168.50.3`) confirma las mediciones desde una fuente externa
al cliente y al servidor:

```
Frame 6   192.168.50.1 → 192.168.50.3   GET / HTTP/1.1
          Accept-Encoding: gzip, deflate

Frame 20  192.168.50.3 → 192.168.50.1   HTTP/1.1 200 OK (text/html)
          Vary: Accept-Encoding
          Content-Encoding: gzip
          Content-Length: 12779
          ETag: "6af4d-65ae96115a13d-gzip"

          [9 Reassembled TCP Segments (13120 bytes)]
          Content-encoded entity body (gzip): 12779 bytes -> 438093 bytes
```

Tres observaciones:

1. **`12779 bytes -> 438093 bytes`** coincide exactamente con la medición de `curl` y con
   el registro de `mod_deflate` (`"GET /index.html HTTP/1.1" 12761/438093 (2%)`). Tres
   fuentes independientes, el mismo resultado.
2. **9 segmentos TCP** en lugar de los ~300 que habrían sido necesarios sin comprimir
   (438.093 / 1.460 bytes de MSS). Menos paquetes implica menos confirmaciones, menos
   oportunidades de pérdida y menos retransmisiones: en redes con pérdida, el beneficio de
   la compresión es mayor que el que sugiere la simple reducción de bytes.
3. **`Accept-Encoding: gzip, deflate`** — el navegador no anunció `br`. Los navegadores
   restringen Brotli a conexiones seguras, por lo que sobre HTTP plano Apache solo puede
   entregar gzip. Que el servidor sí soporta Brotli se comprueba forzando la cabecera con
   `curl`, tal como indica el enunciado.
