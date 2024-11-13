#!/bin/bash

# install_certbot.sh
# Script para instalar Certbot y el plugin de Nginx en Ubuntu 24.04

# Actualizar el sistema
echo "Actualizando el sistema..."
sudo apt update && sudo apt upgrade -y

# Instalar Certbot y el plugin de Nginx
echo "Instalando Certbot y el plugin para Nginx..."
sudo apt install certbot python3-certbot-nginx -y

# Confirmar instalación exitosa
if command -v certbot &> /dev/null
then
    echo "Certbot y el plugin para Nginx se han instalado correctamente."
else
    echo "Hubo un error al instalar Certbot o el plugin para Nginx."
    exit 1
fi