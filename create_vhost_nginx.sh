#!/bin/bash
# create_nginx_vhost.sh
# Script para crear un host virtual en Nginx con SSL en Ubuntu

# Función para eliminar los cambios en caso de error
cleanup() {
    # Eliminar el archivo de configuración de Nginx
    sudo rm -f /etc/nginx/sites-available/$DOMAIN
    sudo rm -f /etc/nginx/sites-enabled/$DOMAIN

    # Eliminar la carpeta del proyecto
    sudo rm -rf $PROJECT_PATH

    # Recargar Nginx
    sudo systemctl reload nginx

    echo "Se han eliminado los cambios realizados por el script."
    exit 1
}

# Solicitar el dominio, la carpeta del proyecto y el correo electrónico al usuario
read -p "Introduce el dominio (e.g., backend.livemusicaruba.com): " DOMAIN
read -p "Introduce el nombre de la carpeta en /home/ubuntu/: " FOLDER
read -p "Introduce el correo electrónico para Certbot: " EMAIL

# Definir la ruta del proyecto
PROJECT_PATH="/home/ubuntu/$FOLDER"

# Crear la carpeta del proyecto si no existe
if [ ! -d "$PROJECT_PATH" ]; then
    mkdir -p "$PROJECT_PATH"
    echo "Carpeta del proyecto creada en $PROJECT_PATH"
else
    echo "La carpeta del proyecto ya existe en $PROJECT_PATH"
    cleanup
fi

# Crear un archivo index.html básico
cat > "$PROJECT_PATH/index.html" << EOL
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Bienvenido a $DOMAIN</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            background-color: #f4f4f4;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background-color: white;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            text-align: center;
        }
        .info {
            background-color: #e9ecef;
            padding: 15px;
            border-radius: 4px;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>¡Servidor Web Configurado Exitosamente!</h1>
        <div class="info">
            <p><strong>IP del Servidor:</strong> $(hostname -I | awk '{print $1}')</p>
            <p><strong>Fecha de Instalación:</strong> $(date)</p>
            <p><strong>Versión de Nginx:</strong> $(nginx -v 2>&1 | awk -F/ '{print $2}')</p>
            <p><strong>Ruta del Proyecto:</strong> $PROJECT_PATH</p>
        </div>
    </div>
</body>
</html>
EOL

# Configurar el archivo de host virtual en Nginx
NGINX_CONFIG="/etc/nginx/sites-available/$DOMAIN"
sudo bash -c "cat > $NGINX_CONFIG" << EOL
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    root $PROJECT_PATH;
    index index.html;
    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOL

# Activar el host virtual
sudo ln -s $NGINX_CONFIG /etc/nginx/sites-enabled/

# Probar y recargar Nginx
sudo nginx -t && sudo systemctl reload nginx || cleanup

# Generar el certificado SSL con Certbot
sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email $EMAIL || cleanup

# Confirmación de éxito
echo "Host virtual para $DOMAIN creado exitosamente con SSL."
echo "Puedes visitar https://$DOMAIN para verificar."