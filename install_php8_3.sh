#!/bin/bash

# Actualizar el sistema
sudo apt update -y
sudo apt upgrade -y

# Instalar dependencias necesarias
sudo apt install -y software-properties-common ca-certificates lsb-release apt-transport-https

# Agregar el repositorio de PHP 8.3
sudo add-apt-repository ppa:ondrej/php -y

# Actualizar los repositorios
sudo apt update -y

# Instalar PHP 8.3 y las extensiones comunes
sudo apt install -y php8.3 php8.3-cli php8.3-fpm php8.3-mysql php8.3-xml php8.3-mbstring php8.3-curl php8.3-zip php8.3-intl php8.3-soap php8.3-bcmath php8.3-gd php8.3-opcache php8.3-readline

# Verificar la instalación de PHP
php -v

# Mensaje final
echo "PHP 8.3 y todas las dependencias comunes se han instalado correctamente."
