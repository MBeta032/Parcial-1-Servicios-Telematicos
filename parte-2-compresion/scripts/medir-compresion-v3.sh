#!/bin/bash
# =============================================================
#  Parcial 1 - Servicios Telematicos - UAO
#  Parte 2: medicion comparativa de compresion  (v3)
#
#  CORRECCION FRENTE A LA v2:
#    curl necesita UN -o POR CADA URL. En la v2 solo habia uno,
#    asi que las 19 respuestas restantes se imprimian en pantalla
#    y contaminaban la salida que awk debia promediar.
#    Ahora se construye la lista como:  -o /dev/null URL  (x N)
#
#  METODOLOGIA:
#    - N peticiones en UNA sola invocacion de curl -> una
#      resolucion DNS y una conexion TCP reutilizada.
#    - Se descarta la primera medicion (incluye DNS y saludo TCP).
#    - t_servidor = time_starttransfer - time_pretransfer
#      Intervalo entre terminar de pedir y recibir el primer byte:
#      ahi ocurre la compresion. Aisla el costo de CPU.
#    - tx_XMbps = tiempo teorico de transmision, porque la medicion
#      es local y el ahorro de ancho de banda no se ve en los tiempos.
#
#  Uso:  sudo bash medir-compresion-v3.sh
# =============================================================

set -u

BASE="http://parcial.empresa.local"
RAIZ="/var/www/parcial"
DEFLATE_CONF="/etc/apache2/mods-available/deflate.conf"
BROTLI_CONF="/etc/apache2/mods-available/brotli.conf"
OUTDIR="/vagrant/parte-2-compresion/resultados"
CSV="$OUTDIR/tabla-comparativa.csv"
MD="$OUTDIR/tabla-comparativa.md"

REPS=20
ENLACE_MBPS=10

ARCHIVOS=(
  "index.html:HTML"
  "estilos.css:CSS sin minificar"
  "estilos.min.css:CSS minificado"
  "app.js:JavaScript (jQuery real)"
  "datos.json:JSON"
  "grafico.svg:SVG"
  "feed.xml:XML"
  "lorem.txt:Texto plano"
  "foto.jpg:Imagen JPEG"
  "imagen.png:Imagen PNG"
  "clip.mp4:Video MP4"
  "paquete.zip:Archivo ZIP"
)

mkdir -p "$OUTDIR"

nivel_deflate() {
    sed -i "s/^\([[:space:]]*\)DeflateCompressionLevel .*/\1DeflateCompressionLevel $1/" "$DEFLATE_CONF"
    systemctl reload apache2; sleep 1
}

calidad_brotli() {
    sed -i "s/^\([[:space:]]*\)BrotliCompressionQuality .*/\1BrotliCompressionQuality $1/" "$BROTLI_CONF"
    systemctl reload apache2; sleep 1
}

# medir <archivo> <accept-encoding>  ->  "bytes t_total_ms t_servidor_ms"
medir() {
    local archivo="$1" enc="$2"
    local url="$BASE/$archivo"

    # Calentamiento
    curl -s -H "Accept-Encoding: $enc" -o /dev/null "$url" 2>/dev/null

    # UN -o POR CADA URL  <- esta es la correccion
    local args=()
    local i
    for ((i=0; i<REPS; i++)); do
        args+=(-o /dev/null "$url")
    done

    curl -s -H "Accept-Encoding: $enc" \
         -w '%{size_download} %{time_pretransfer} %{time_starttransfer} %{time_total}\n' \
         "${args[@]}" 2>/dev/null \
    | tail -n +2 \
    | awk '
        $1 ~ /^[0-9]+$/ {
            bytes = $1
            s = $3 - $2; if (s < 0) s = 0
            servidor += s
            total    += $4
            n++
        }
        END {
            if (n == 0) { print "ERROR 0 0"; exit }
            printf "%d %.3f %.3f", bytes, (total/n)*1000, (servidor/n)*1000
        }'
}

tx_ms() {
    awk -v b="$1" -v m="$2" 'BEGIN{ printf "%.1f", (b*8)/(m*1000000)*1000 }'
}

# calcula ratio con guarda contra division por cero
calc_ratio() {
    awk -v c="$1" -v o="$2" 'BEGIN{ if (o+0 == 0) print "n/a"; else printf "%.3f", c/o }'
}

calc_ahorro() {
    awk -v r="$1" 'BEGIN{ if (r == "n/a") print "n/a"; else printf "%.1f", (1-r)*100 }'
}

# -------------------------------------------------------------
#  Comprobacion previa
# -------------------------------------------------------------
echo "==> Comprobando que los archivos existen y responden"
FALTAN=0
for entrada in "${ARCHIVOS[@]}"; do
    archivo="${entrada%%:*}"
    if [ ! -f "$RAIZ/$archivo" ]; then
        echo "    FALTA: $archivo"; FALTAN=1
    fi
done
[ "$FALTAN" -eq 1 ] && echo "    (los archivos faltantes se omiten)"

# -------------------------------------------------------------
#  Linea base
# -------------------------------------------------------------
echo ""
echo "==> Linea base sin comprimir (identity)"
declare -A BASE_B BASE_T BASE_S
for entrada in "${ARCHIVOS[@]}"; do
    archivo="${entrada%%:*}"
    [ -f "$RAIZ/$archivo" ] || continue
    read -r b t s <<< "$(medir "$archivo" "identity")"
    real=$(stat -c%s "$RAIZ/$archivo")
    if [ "$b" != "$real" ]; then
        echo "    AVISO: $archivo devolvio $b B pero en disco pesa $real B"
    fi
    BASE_B["$archivo"]="$b"; BASE_T["$archivo"]="$t"; BASE_S["$archivo"]="$s"
    printf "    %-18s %10s B   total %8s ms   servidor %8s ms\n" "$archivo" "$b" "$t" "$s"
done

# -------------------------------------------------------------
#  Cabeceras de salida
# -------------------------------------------------------------
echo "archivo,tipo,algoritmo,nivel,bytes,ratio,ahorro_pct,t_total_ms,t_servidor_ms,tx_${ENLACE_MBPS}mbps_ms" > "$CSV"

{
  echo "# Tabla comparativa de compresion — Parte 2"
  echo ""
  echo "**Parcial 1 · Servicios Telematicos · UAO**"
  echo ""
  echo "## Metodologia"
  echo ""
  echo "- Servidor: Apache 2.4.52 sobre \`maestro\` (192.168.50.3), 2 GB RAM, 1 vCPU."
  echo "- Dominio \`parcial.empresa.local\`, resuelto por el DNS esclavo de la Parte 1."
  echo "- **$REPS peticiones por medicion en una unica invocacion de curl**, sobre la"
  echo "  misma conexion TCP. Se descarta la primera para excluir la resolucion DNS"
  echo "  y el saludo TCP, que no forman parte del costo de compresion."
  echo "- **t_servidor** = \`time_starttransfer - time_pretransfer\`: intervalo entre"
  echo "  terminar de enviar la peticion y recibir el primer byte. Ahi ocurre la"
  echo "  compresion, asi que aisla el costo de CPU del resto de la latencia."
  echo "- **tx_${ENLACE_MBPS}mbps**: tiempo teorico de transmision sobre un enlace de"
  echo "  ${ENLACE_MBPS} Mbps. La medicion es local (cliente y servidor en la misma"
  echo "  maquina), asi que el ahorro de ancho de banda no aparece en los tiempos"
  echo "  medidos; este calculo lo hace visible."
  echo "- Ratio = comprimido / original (menor es mejor) · Ahorro % = (1 - ratio) × 100"
  echo ""
} > "$MD"

# -------------------------------------------------------------
#  Recorrido principal
# -------------------------------------------------------------
for entrada in "${ARCHIVOS[@]}"; do
    archivo="${entrada%%:*}"
    tipo="${entrada##*:}"
    [ -f "$RAIZ/$archivo" ] || continue

    ob="${BASE_B[$archivo]}"; ot="${BASE_T[$archivo]}"; os="${BASE_S[$archivo]}"
    otx=$(tx_ms "$ob" "$ENLACE_MBPS")

    echo ""
    echo "============================================================"
    echo " $archivo  ($tipo)  -  original: $ob bytes"
    echo "============================================================"
    printf "    %-22s %10s %8s %9s %11s %11s\n" "COMBINACION" "BYTES" "RATIO" "AHORRO" "SERVIDOR" "TX@${ENLACE_MBPS}Mbps"
    printf "    %-22s %10s %8s %8s%% %9sms %9sms\n" "sin comprimir" "$ob" "1.000" "0.0" "$os" "$otx"

    {
      echo "## \`$archivo\` — $tipo"
      echo ""
      echo "Tamano original: **$ob bytes**"
      echo ""
      echo "| Algoritmo / nivel | Tamano (B) | Ratio | Ahorro % | t servidor (ms) | t total (ms) | Transmision @ ${ENLACE_MBPS} Mbps (ms) |"
      echo "| :--- | ---: | ---: | ---: | ---: | ---: | ---: |"
      echo "| Sin comprimir (base) | $ob | 1.000 | 0.0 % | $os | $ot | $otx |"
    } >> "$MD"

    echo "$archivo,$tipo,identity,-,$ob,1.000,0.0,$ot,$os,$otx" >> "$CSV"

    for nivel in 1 6 9; do
        nivel_deflate "$nivel"
        read -r b t s <<< "$(medir "$archivo" "gzip")"
        ratio=$(calc_ratio "$b" "$ob")
        ahorro=$(calc_ahorro "$ratio")
        tx=$(tx_ms "$b" "$ENLACE_MBPS")
        printf "    %-22s %10s %8s %8s%% %9sms %9sms\n" "gzip nivel $nivel" "$b" "$ratio" "$ahorro" "$s" "$tx"
        echo "$archivo,$tipo,gzip,$nivel,$b,$ratio,$ahorro,$t,$s,$tx" >> "$CSV"
        echo "| gzip nivel $nivel | $b | $ratio | $ahorro % | $s | $t | $tx |" >> "$MD"
    done

    for cal in 5 11; do
        calidad_brotli "$cal"
        read -r b t s <<< "$(medir "$archivo" "br")"
        ratio=$(calc_ratio "$b" "$ob")
        ahorro=$(calc_ahorro "$ratio")
        tx=$(tx_ms "$b" "$ENLACE_MBPS")
        printf "    %-22s %10s %8s %8s%% %9sms %9sms\n" "brotli calidad $cal" "$b" "$ratio" "$ahorro" "$s" "$tx"
        echo "$archivo,$tipo,brotli,$cal,$b,$ratio,$ahorro,$t,$s,$tx" >> "$CSV"
        echo "| brotli calidad $cal | $b | $ratio | $ahorro % | $s | $t | $tx |" >> "$MD"
    done

    echo "" >> "$MD"
done

echo ""
echo "==> Restaurando valores por defecto (deflate 6 / brotli 11)"
nivel_deflate 6
calidad_brotli 11

echo ""
echo "============================================================"
echo "  CSV      : $CSV"
echo "  Markdown : $MD"
echo "============================================================"
