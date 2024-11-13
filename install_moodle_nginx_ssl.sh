#!/bin/bash

# Verificar que el script se esté ejecutando como root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecute este script como root o usando sudo."
  exit 1
fi

# Solicitar variables necesarias
read -p "Ingrese la URL de la base de datos: " db_url
read -p "Ingrese el nombre de la base de datos: " db_name
read -p "Ingrese el usuario de la base de datos: " db_user
read -sp "Ingrese la contraseña de la base de datos: " db_password
echo
read -p "Ingrese la ubicación de los archivos de Moodle (/var/www/html/moodle por defecto): " moodle_dir
moodle_dir=${moodle_dir:-/var/www/html/moodle}
read -p "Ingrese el directorio de datos de Moodle (/var/moodledata por defecto): " moodle_data_dir
moodle_data_dir=${moodle_data_dir:-/var/moodledata}
read -p "Ingrese el dominio que se le va a asignar a Moodle: " moodle_domain

# Actualizar el sistema
apt update -y
apt upgrade -y

# Descargar Moodle
mkdir -p $moodle_dir
cd /tmp
if ! git clone -b MOODLE_405_STABLE git://git.moodle.org/moodle.git $moodle_dir; then
    echo "Error al clonar Moodle desde el repositorio Git. Eliminando archivos creados..."
    rm -rf $moodle_dir
    exit 1
fi

# Configurar permisos para Moodle
chown -R www-data:www-data $moodle_dir
chmod -R 755 $moodle_dir

# Crear directorio de datos de Moodle
mkdir -p $moodle_data_dir
chown -R www-data:www-data $moodle_data_dir
chmod -R 777 $moodle_data_dir

# Crear Virtual Host para Nginx
nginx_vhost="server {
    listen 80;
    server_name $moodle_domain;
    root $moodle_dir;

    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~* /\. { 
        deny all;
    }
}"

echo "$nginx_vhost" | tee /etc/nginx/sites-available/moodle

# Activar configuración de Nginx
if ! ln -s /etc/nginx/sites-available/moodle /etc/nginx/sites-enabled/; then
    echo "Error al activar la configuración de Nginx. Eliminando archivos creados..."
    rm -rf $moodle_dir $moodle_data_dir /etc/nginx/sites-available/moodle /etc/nginx/sites-enabled/moodle
    exit 1
fi

if ! nginx -t; then
    echo "Error en la configuración de Nginx. Eliminando archivos creados..."
    rm -rf $moodle_dir $moodle_data_dir /etc/nginx/sites-available/moodle /etc/nginx/sites-enabled/moodle
    exit 1
fi

systemctl restart nginx

# Crear archivo config.php de Moodle
cp $moodle_dir/config-dist.php $moodle_dir/config.php
sed -i "s|\$CFG->dbhost    = 'localhost';|\$CFG->dbhost    = '$db_url';|" $moodle_dir/config.php
sed -i "s|\$CFG->dbname    = 'moodle';|\$CFG->dbname    = '$db_name';|" $moodle_dir/config.php
sed -i "s|\$CFG->dbuser    = 'username';|\$CFG->dbuser    = '$db_user';|" $moodle_dir/config.php
sed -i "s|\$CFG->dbpass    = 'password';|\$CFG->dbpass    = '$db_password';|" $moodle_dir/config.php
sed -i "s|\$CFG->wwwroot   = 'http://example.com/moodle';|\$CFG->wwwroot   = 'http://$moodle_domain';|" $moodle_dir/config.php
sed -i "s|\$CFG->dataroot  = '/your/moodledata/here';|\$CFG->dataroot  = '$moodle_data_dir';|" $moodle_dir/config.php

# Generar certificado SSL con Certbot
if ! certbot --nginx -d $moodle_domain; then
    echo "Error al generar el certificado SSL. Eliminando archivos creados..."
    rm -rf $moodle_dir $moodle_data_dir /etc/nginx/sites-available/moodle /etc/nginx/sites-enabled/moodle
    exit 1
fi

# Mensaje final
echo "Moodle 4.5 se ha instalado correctamente en el servidor con Nginx y SSL configurado para $moodle_domain."
echo "Puede acceder a su sitio Moodle en https://$moodle_domain."