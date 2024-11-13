#!/bin/bash

# Verificar si se está ejecutando como root
if [ "$EUID" -ne 0 ]; then
    echo "Este script debe ejecutarse como root (usar sudo)"
    exit 1
fi


# Obtener la IP pública del servidor
PUBLIC_IP=$(curl -s ifconfig.me)
if [ -z "$PUBLIC_IP" ]; then
    echo "No se pudo obtener la IP pública del servidor"
    exit 1
fi

echo "IP Pública detectada: $PUBLIC_IP"

# Actualizar los repositorios e instalar actualizaciones
echo "Actualizando el sistema..."
apt update && apt upgrade -y

# Instalar Nginx
echo "Instalando Nginx..."
apt install nginx -y

# Configurar el firewall
echo "Configurando el firewall..."
ufw allow 'Nginx Full'
ufw status

# Crear directorio para el proyecto
SITE_DIR="/home/ubuntu/info"
mkdir -p $SITE_DIR

# Crear una página web de prueba
cat > $SITE_DIR/index.html << EOF
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Bienvenido a $PUBLIC_IP</title>
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
            <p><strong>IP del Servidor:</strong> $PUBLIC_IP</p>
            <p><strong>Fecha de Instalación:</strong> $(date)</p>
            <p><strong>Versión de Nginx:</strong> $(nginx -v 2>&1 | cut -d'/' -f2)</p>
            <p><strong>Ruta del Proyecto:</strong> $SITE_DIR</p>
        </div>
    </div>
</body>
</html>
EOF

# Crear la configuración del virtual host
cat > /etc/nginx/sites-available/$PUBLIC_IP << EOF
server {
    listen 80;
    listen [::]:80;

    root $SITE_DIR;
    index index.html index.htm;

    server_name $PUBLIC_IP;

    access_log /var/log/nginx/${PUBLIC_IP}_access.log;
    error_log /var/log/nginx/${PUBLIC_IP}_error.log;

    location / {
        try_files \$uri \$uri/ =404;
    }

    # Configuración adicional de seguridad
    location ~ /\. {
        deny all;
    }

    # Configuración para archivos estáticos
    location ~* \.(jpg|jpeg|gif|png|css|js|ico|xml)$ {
        expires 5d;
    }
}
EOF

# Establecer permisos correctos para el directorio y archivos
chown -R ubuntu:ubuntu $SITE_DIR
chmod -R 755 $SITE_DIR

# Asegurarse que nginx pueda acceder al directorio home de ubuntu
chmod 755 /home/ubuntu

# Habilitar el sitio
ln -sf /etc/nginx/sites-available/$PUBLIC_IP /etc/nginx/sites-enabled/

# Verificar la configuración de Nginx
nginx -t

# Eliminar el default site si existe
rm -f /etc/nginx/sites-enabled/default

# Reiniciar Nginx
systemctl restart nginx

echo "==================================================="
echo "Instalación completada exitosamente!"
echo "Tu sitio web está disponible en: http://$PUBLIC_IP"
echo "Directorio del sitio web: $SITE_DIR"
echo "Archivo de configuración: /etc/nginx/sites-available/$PUBLIC_IP"
echo "Logs de acceso: /var/log/nginx/${PUBLIC_IP}_access.log"
echo "Logs de error: /var/log/nginx/${PUBLIC_IP}_error.log"
echo ""
echo "NOTA: El directorio del sitio pertenece al usuario 'ubuntu'"
echo "      Puedes modificar los archivos directamente con ese usuario"
echo "==================================================="