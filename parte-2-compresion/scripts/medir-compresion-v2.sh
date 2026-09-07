#!/bin/bash
# =============================================================
#  Parcial 1 - Servicios Telematicos - UAO
#  Parte 2: medicion comparativa de compresion  (v2)
#
#  MEJORAS FRENTE A LA v1:
#
#  1. REUTILIZACION DE CONEXION
#     La v1 lanzaba 20 procesos curl independientes, cada uno con
#     su propia resolucion DNS y su propio saludo TCP. Eso dispara
#     el rate limiting del DNS (Requisito 7) y contamina el tiempo.
#     Ahora se hace UNA sola invocacion de curl con la URL repetida:
#     una resolucion DNS, una conexion, N peticiones.
#
#  2. TIEMPO DE SERVIDOR AISLADO
#     t_servidor = time_starttransfer - time_pretransfer
#     Es el tiempo entre "termine de pedir" y "llego el primer byte":
#     justo donde ocurre la compresion. Excluye DNS, TCP y descarga.
#
#  3. TIEMPO DE TRANSMISION ESTIMADO
#     La medicion local no tiene red real, asi que el ahorro de
#     ancho de banda no se ve. Se calcula cuanto tardaria el mismo
#     contenido sobre enlaces de 10 Mbps y 1 Mbps.
#
#  Uso:  sudo bash medir-compresion-v2.sh
# =============================================================

set -u

BASE="http://parcial.empresa.local"
DEFLATE_CONF="/etc/apache2/mods-available/deflate.conf"
BROTLI_CONF="/etc/apache2/mods-available/brotli.conf"
OUTDIR="/vagrant/parte-2-compresion/resultados"
CSV="$OUTDIR/tabla-comparativa.csv"
MD="$OUTDIR/tabla-comparativa.md"

REPS=20          # peticiones por medicion, sobre la misma conexion
ENLACE_MBPS=10   # enlace de referencia para el tiempo de transmision

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

    # Calentamiento: descarta el primer acceso a disco
    curl -s -H "Accept-Encoding: $enc" -o /dev/null "$url" 2>/dev/null

    # La URL repetida REPS veces -> una sola conexion reutilizada
    local urls=()
    local i
    for ((i=0; i<REPS; i++)); do urls+=("$url"); done

    # Se descarta la PRIMERA linea: incluye DNS y saludo TCP
    curl -s -H "Accept-Encoding: $enc" -o /dev/null \
         -w '%{size_download} %{time_pretransfer} %{time_starttransfer} %{time_total}\n' \
         "${urls[@]}" 2>/dev/null \
    | tail -n +2 \
    | awk '{
            bytes = $1
            servidor += ($3 - $2)
            total    += $4
            n++
          }
          END {
            if (n == 0) { print "0 0 0"; exit }
            printf "%d %.3f %.3f", bytes, (total/n)*1000, (servidor/n)*1000
          }'
}

# tiempo de transmision teorico en ms para N bytes sobre X Mbps
tx_ms() {
    awk -v b="$1" -v m="$2" 'BEGIN{ printf "%.1f", (b*8)/(m*1000000)*1000 }'
}

# -------------------------------------------------------------
#  Linea base
# -------------------------------------------------------------
echo "==> Linea base sin comprimir (identity)"
declare -A BASE_B BASE_T BASE_S
for entrada in "${ARCHIVOS[@]}"; do
    archivo="${entrada%%:*}"
    [ -f "/var/www/parcial/$archivo" ] || continue
    read -r b t s <<< "$(medir "$archivo" "identity")"
    BASE_B["$archivo"]="$b"; BASE_T["$archivo"]="$t"; BASE_S["$archivo"]="$s"
    printf "    %-18s %10s B   total %7s ms   servidor %7s ms\n" "$archivo" "$b" "$t" "$s"
done

# -------------------------------------------------------------
#  Cabeceras
# -------------------------------------------------------------
echo "archivo,tipo,algoritmo,nivel,bytes,ratio,ahorro_pct,t_total_ms,t_servidor_ms,tx_${ENLACE_MBPS}mbps_ms" > "$CSV"

{
  echo "# Tabla comparativa de compresion — Parte 2"
  echo ""
  echo "**Parcial 1 · Servicios Telematicos · UAO**"
  echo ""
  echo "## Metodologia"
  echo ""
  echo "- Servidor: Apache 2.4.52 sobre \`maestro\` (192.168.50.3), 2 GB RAM, 1 vCPU"
  echo "- Dominio \`parcial.empresa.local\`, resuelto por el DNS esclavo de la Parte 1"
  echo "- **$REPS peticiones por medicion sobre una unica conexion reutilizada.**"
  echo "  Se descarta la primera para excluir la resolucion DNS y el saludo TCP."
  echo "- **t_servidor** = \`time_starttransfer - time_pretransfer\`. Es el intervalo"
  echo "  entre terminar de enviar la peticion y recibir el primer byte: ahi ocurre"
  echo "  la compresion. Aisla el costo de CPU del resto de la latencia."
  echo "- **tx_${ENLACE_MBPS}mbps** = tiempo teorico de transmision sobre un enlace de"
  echo "  ${ENLACE_MBPS} Mbps. La medicion es local (sin red real), asi que el ahorro de"
  echo "  ancho de banda no aparece en los tiempos medidos; este calculo lo estima."
  echo "- Ratio = comprimido / original (menor es mejor) · Ahorro % = (1 - ratio) x 100"
  echo ""
} > "$MD"

# -------------------------------------------------------------
#  Recorrido
# -------------------------------------------------------------
for entrada in "${ARCHIVOS[@]}"; do
    archivo="${entrada%%:*}"
    tipo="${entrada##*:}"
    [ -f "/var/www/parcial/$archivo" ] || continue

    ob="${BASE_B[$archivo]}"; ot="${BASE_T[$archivo]}"; os="${BASE_S[$archivo]}"
    otx=$(tx_ms "$ob" "$ENLACE_MBPS")

    echo ""
    echo "============================================================"
    echo " $archivo  ($tipo)  -  original: $ob bytes"
    echo "============================================================"
    printf "    %-22s %10s %8s %9s %9s %11s\n" "COMBINACION" "BYTES" "RATIO" "AHORRO" "SERVIDOR" "TX@${ENLACE_MBPS}Mbps"
    printf "    %-22s %10s %8s %8s%% %8sms %9sms\n" "sin comprimir" "$ob" "1.000" "0.0" "$os" "$otx"

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
        ratio=$(awk -v c="$b" -v o="$ob" 'BEGIN{printf "%.3f", c/o}')
        ahorro=$(awk -v r="$ratio" 'BEGIN{printf "%.1f", (1-r)*100}')
        tx=$(tx_ms "$b" "$ENLACE_MBPS")
        printf "    %-22s %10s %8s %8s%% %8sms %9sms\n" "gzip nivel $nivel" "$b" "$ratio" "$ahorro" "$s" "$tx"
        echo "$archivo,$tipo,gzip,$nivel,$b,$ratio,$ahorro,$t,$s,$tx" >> "$CSV"
        echo "| gzip nivel $nivel | $b | $ratio | $ahorro % | $s | $t | $tx |" >> "$MD"
    done

    for cal in 5 11; do
        calidad_brotli "$cal"
        read -r b t s <<< "$(medir "$archivo" "br")"
        ratio=$(awk -v c="$b" -v o="$ob" 'BEGIN{printf "%.3f", c/o}')
        ahorro=$(awk -v r="$ratio" 'BEGIN{printf "%.1f", (1-r)*100}')
        tx=$(tx_ms "$b" "$ENLACE_MBPS")
        printf "    %-22s %10s %8s %8s%% %8sms %9sms\n" "brotli calidad $cal" "$b" "$ratio" "$ahorro" "$s" "$tx"
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
