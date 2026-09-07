#!/bin/bash
# =============================================================
#  Parcial 1 - Servicios Telematicos - UAO
#  Parte 2: generacion del sitio de prueba
#
#  Crea en /var/www/parcial todos los tipos de archivo que pide
#  la tabla de la pagina 5 del enunciado, con tamanos suficientes
#  para que las diferencias de compresion sean medibles.
#
#  Uso:  sudo bash generar-sitio.sh
# =============================================================

set -e

DEST="/var/www/parcial"
TMP="/tmp/sitio-parcial"

echo "==> Preparando directorios"
mkdir -p "$DEST"
rm -rf "$TMP"
mkdir -p "$TMP"
cd "$TMP"

# -------------------------------------------------------------
# 1. TEXTO PLANO  ->  lorem.txt  (> 1 MB)
# -------------------------------------------------------------
echo "==> Generando lorem.txt"
PARRAFO="Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur."
for i in $(seq 1 4000); do echo "$PARRAFO"; done > lorem.txt

# -------------------------------------------------------------
# 2. HTML  ->  index.html  (~350 KB)
# -------------------------------------------------------------
echo "==> Generando index.html"
{
  echo '<!DOCTYPE html>'
  echo '<html lang="es">'
  echo '<head>'
  echo '  <meta charset="utf-8">'
  echo '  <title>Parcial 1 - Sitio de prueba de compresion</title>'
  echo '  <link rel="stylesheet" href="estilos.css">'
  echo '</head>'
  echo '<body>'
  echo '  <h1>Parcial 1 - Servicios Telematicos</h1>'
  echo '  <p>Sitio de prueba para medir mod_deflate y mod_brotli.</p>'
  for i in $(seq 1 2000); do
    echo "  <section class=\"item\"><h2>Registro $i</h2><p>Contenido de prueba numero $i para medir la compresion HTTP. El texto se repite a proposito porque los algoritmos LZ77 y Brotli aprovechan la redundancia.</p></section>"
  done
  echo '</body>'
  echo '</html>'
} > index.html

# -------------------------------------------------------------
# 3. CSS  ->  estilos.css  y  estilos.min.css
# -------------------------------------------------------------
echo "==> Generando estilos.css y estilos.min.css"
{
  for i in $(seq 1 1500); do
    echo ".clase-$i {"
    echo "    color: #333333;"
    echo "    background-color: #ffffff;"
    echo "    margin: 10px 15px;"
    echo "    padding: 5px 8px;"
    echo "    border: 1px solid #cccccc;"
    echo "    font-family: Arial, sans-serif;"
    echo "}"
    echo ""
  done
} > estilos.css

sed 's/^[ \t]*//' estilos.css | tr -d '\n' > estilos.min.css

# -------------------------------------------------------------
# 4. JSON  ->  datos.json  (dataset grande)
# -------------------------------------------------------------
echo "==> Generando datos.json"
{
  echo '['
  for i in $(seq 1 8000); do
    printf '  {"id": %d, "nombre": "Usuario %d", "correo": "usuario%d@empresa.local", "ciudad": "Cali", "departamento": "Valle del Cauca", "activo": true, "rol": "empleado"}' "$i" "$i" "$i"
    if [ "$i" -lt 8000 ]; then echo ','; else echo ''; fi
  done
  echo ']'
} > datos.json

# -------------------------------------------------------------
# 5. SVG  ->  grafico.svg
# -------------------------------------------------------------
echo "==> Generando grafico.svg"
{
  echo '<?xml version="1.0" encoding="UTF-8"?>'
  echo '<svg xmlns="http://www.w3.org/2000/svg" width="800" height="600">'
  for i in $(seq 1 4000); do
    echo "  <circle cx=\"$((RANDOM % 800))\" cy=\"$((RANDOM % 600))\" r=\"4\" fill=\"#3366cc\" stroke=\"#000000\" stroke-width=\"1\"/>"
  done
  echo '</svg>'
} > grafico.svg

# -------------------------------------------------------------
# 6. XML  ->  feed.xml
# -------------------------------------------------------------
echo "==> Generando feed.xml"
{
  echo '<?xml version="1.0" encoding="UTF-8"?>'
  echo '<rss version="2.0"><channel>'
  echo '  <title>Empresa Local - Noticias</title>'
  for i in $(seq 1 4000); do
    echo "  <item><title>Noticia $i</title><link>http://parcial.empresa.local/noticia-$i</link><description>Descripcion de la noticia numero $i para pruebas de compresion HTTP.</description></item>"
  done
  echo '</channel></rss>'
} > feed.xml

# -------------------------------------------------------------
# 7. JAVASCRIPT  ->  app.js  (biblioteca real: jQuery)
# -------------------------------------------------------------
echo "==> Descargando app.js (jQuery sin minificar)"
if curl -fsSL -o app.js https://code.jquery.com/jquery-3.7.1.js; then
  echo "    OK - jQuery descargado"
else
  echo "    Sin internet: generando app.js sintetico"
  {
    echo '// Biblioteca de prueba - Parcial 1'
    for i in $(seq 1 4000); do
      echo "function procesarRegistro$i(datos) { var resultado = datos.valor * $i; console.log('Procesando registro $i:', resultado); return resultado; }"
    done
  } > app.js
fi

# -------------------------------------------------------------
# 8. IMAGENES  ->  foto.jpg  e  imagen.png  (YA COMPRIMIDAS)
# -------------------------------------------------------------
echo "==> Descargando imagenes de prueba"
curl -fsSL -o foto.jpg   "https://picsum.photos/seed/parcial1/1600/1200"  || echo "    (foto.jpg no disponible)"
curl -fsSL -o imagen.png "https://picsum.photos/seed/parcial2/1200/900.png" || echo "    (imagen.png no disponible)"

# -------------------------------------------------------------
# 9. ZIP  ->  paquete.zip  (YA COMPRIMIDO)
# -------------------------------------------------------------
echo "==> Generando paquete.zip"
if ! command -v zip > /dev/null; then
  apt-get install -y zip > /dev/null 2>&1 || true
fi
zip -9 -q paquete.zip lorem.txt datos.json index.html feed.xml || echo "    (zip no disponible)"

# -------------------------------------------------------------
# 10. VIDEO  ->  clip.mp4  (opcional, YA COMPRIMIDO)
# -------------------------------------------------------------
echo "==> Intentando descargar clip.mp4"
curl -fsSL -o clip.mp4 "https://download.samplelib.com/mp4/sample-5s.mp4" || echo "    (clip.mp4 no disponible - paquete.zip cubre la categoria)"

# -------------------------------------------------------------
#  Publicar
# -------------------------------------------------------------
echo "==> Publicando en $DEST"
cp -f "$TMP"/* "$DEST"/ 2>/dev/null || true
chown -R www-data:www-data "$DEST"
find "$DEST" -type f -exec chmod 644 {} \;
chmod 755 "$DEST"

echo ""
echo "============================================================"
echo " SITIO PUBLICADO EN $DEST"
echo "============================================================"
ls -lh "$DEST"
echo ""
echo "Tamanos sin comprimir (linea base para la tabla comparativa):"
du -b "$DEST"/* | awk '{printf "  %-28s %10d bytes\n", $2, $1}'
