#!/bin/bash
# =============================================================
#  Parcial 1 - Servicios Telematicos - UAO
#  Parte 2: medicion comparativa de compresion
#
#  Mide cada archivo del sitio con:
#     - identity  (sin comprimir, linea base)
#     - gzip nivel 1, 6 y 9     (mod_deflate)
#     - brotli calidad 5 y 11   (mod_brotli)
#
#  Para cada combinacion registra: bytes, ratio, ahorro % y
#  tiempo medio por peticion (promedio de N repeticiones).
#
#  Uso:  sudo bash medir-compresion.sh
# =============================================================

set -u

BASE="http://parcial.empresa.local"
DEFLATE_CONF="/etc/apache2/mods-available/deflate.conf"
BROTLI_CONF="/etc/apache2/mods-available/brotli.conf"
OUTDIR="/vagrant/parte-2-compresion/resultados"
CSV="$OUTDIR/tabla-comparativa.csv"
MD="$OUTDIR/tabla-comparativa.md"

# Repeticiones por medicion: mas repeticiones = tiempo mas estable
REPS=20

# Archivos a medir  (nombre:tipo)
ARCHIVOS=(
  "index.html:HTML"
  "estilos.css:CSS sin minificar"
  "estilos.min.css:CSS minificado"
  "app.js:JavaScript"
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

# -------------------------------------------------------------
#  Funciones auxiliares
# -------------------------------------------------------------

nivel_deflate() {
    sed -i "s/^\([[:space:]]*\)DeflateCompressionLevel .*/\1DeflateCompressionLevel $1/" "$DEFLATE_CONF"
    systemctl reload apache2
    sleep 1
}

calidad_brotli() {
    sed -i "s/^\([[:space:]]*\)BrotliCompressionQuality .*/\1BrotliCompressionQuality $1/" "$BROTLI_CONF"
    systemctl reload apache2
    sleep 1
}

# medir <archivo> <accept-encoding>  ->  imprime "bytes tiempo_ms"
medir() {
    local archivo="$1" enc="$2"
    local url="$BASE/$archivo"

    # Peticion de calentamiento (descarta el primer acceso a disco)
    curl -s -H "Accept-Encoding: $enc" -o /dev/null "$url" 2>/dev/null

    local bytes
    bytes=$(curl -s -H "Accept-Encoding: $enc" -o /dev/null -w '%{size_download}' "$url" 2>/dev/null)

    local inicio fin
    inicio=$(date +%s%N)
    for _ in $(seq 1 "$REPS"); do
        curl -s -H "Accept-Encoding: $enc" -o /dev/null "$url" 2>/dev/null
    done
    fin=$(date +%s%N)

    local ms
    ms=$(awk -v a="$inicio" -v b="$fin" -v n="$REPS" 'BEGIN{printf "%.3f", (b-a)/1000000/n}')
    echo "$bytes $ms"
}

# -------------------------------------------------------------
#  1. Linea base sin comprimir
# -------------------------------------------------------------
echo "==> Midiendo linea base (identity)..."
declare -A BASELINE
for entrada in "${ARCHIVOS[@]}"; do
    archivo="${entrada%%:*}"
    [ -f "/var/www/parcial/$archivo" ] || continue
    read -r b t <<< "$(medir "$archivo" "identity")"
    BASELINE["$archivo"]="$b $t"
    printf "    %-20s %10s bytes  %8s ms\n" "$archivo" "$b" "$t"
done

# -------------------------------------------------------------
#  2. Encabezados de salida
# -------------------------------------------------------------
echo "archivo,tipo,algoritmo,nivel,bytes,ratio,ahorro_pct,tiempo_ms" > "$CSV"

{
  echo "# Tabla comparativa de compresion - Parte 2"
  echo ""
  echo "**Parcial 1 - Servicios Telematicos - UAO**"
  echo ""
  echo "- Servidor: Apache 2.4 sobre \`maestro\` (192.168.50.3)"
  echo "- Dominio: \`parcial.empresa.local\` (resuelto por el DNS de la Parte 1)"
  echo "- Ratio = comprimido / original (menor es mejor)"
  echo "- Ahorro % = (1 - ratio) x 100"
  echo "- Tiempo = promedio de $REPS peticiones, medicion local"
  echo ""
} > "$MD"

# -------------------------------------------------------------
#  3. Recorrer combinaciones
# -------------------------------------------------------------
for entrada in "${ARCHIVOS[@]}"; do
    archivo="${entrada%%:*}"
    tipo="${entrada##*:}"
    [ -f "/var/www/parcial/$archivo" ] || continue

    read -r base_b base_t <<< "${BASELINE[$archivo]}"

    echo ""
    echo "============================================================"
    echo " $archivo  ($tipo)  -  original: $base_b bytes"
    echo "============================================================"

    {
      echo "## \`$archivo\` — $tipo"
      echo ""
      echo "**Tamano original: $base_b bytes**"
      echo ""
      echo "| Algoritmo / nivel | Tamano (B) | Ratio | Ahorro % | Tiempo (ms) |"
      echo "| :--- | ---: | ---: | ---: | ---: |"
      echo "| Sin comprimir (base) | $base_b | 1.000 | 0.0 % | $base_t |"
    } >> "$MD"

    echo "$archivo,$tipo,identity,-,$base_b,1.000,0.0,$base_t" >> "$CSV"

    printf "    %-22s %10s  %7s  %8s  %9s\n" "SIN COMPRIMIR" "$base_b" "1.000" "0.0%" "$base_t"

    # ---- gzip niveles 1, 6, 9 ----
    for nivel in 1 6 9; do
        nivel_deflate "$nivel"
        read -r b t <<< "$(medir "$archivo" "gzip")"
        ratio=$(awk -v c="$b" -v o="$base_b" 'BEGIN{printf "%.3f", c/o}')
        ahorro=$(awk -v r="$ratio" 'BEGIN{printf "%.1f", (1-r)*100}')
        printf "    %-22s %10s  %7s  %7s%%  %9s\n" "gzip nivel $nivel" "$b" "$ratio" "$ahorro" "$t"
        echo "$archivo,$tipo,gzip,$nivel,$b,$ratio,$ahorro,$t" >> "$CSV"
        echo "| gzip nivel $nivel | $b | $ratio | $ahorro % | $t |" >> "$MD"
    done

    # ---- brotli calidades 5 y 11 ----
    for cal in 5 11; do
        calidad_brotli "$cal"
        read -r b t <<< "$(medir "$archivo" "br")"
        ratio=$(awk -v c="$b" -v o="$base_b" 'BEGIN{printf "%.3f", c/o}')
        ahorro=$(awk -v r="$ratio" 'BEGIN{printf "%.1f", (1-r)*100}')
        printf "    %-22s %10s  %7s  %7s%%  %9s\n" "brotli calidad $cal" "$b" "$ratio" "$ahorro" "$t"
        echo "$archivo,$tipo,brotli,$cal,$b,$ratio,$ahorro,$t" >> "$CSV"
        echo "| brotli calidad $cal | $b | $ratio | $ahorro % | $t |" >> "$MD"
    done

    echo "" >> "$MD"
done

# -------------------------------------------------------------
#  4. Restaurar valores por defecto
# -------------------------------------------------------------
echo ""
echo "==> Restaurando DeflateCompressionLevel 6 y BrotliCompressionQuality 11"
nivel_deflate 6
calidad_brotli 11

echo ""
echo "============================================================"
echo " RESULTADOS GUARDADOS"
echo "============================================================"
echo "  CSV      : $CSV"
echo "  Markdown : $MD"
