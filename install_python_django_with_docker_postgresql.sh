#!/bin/bash

# Solicitar información al usuario
read -p "Nombre de la base de datos: " DB_NAME
read -s -p "Contraseña de la base de datos: " DB_PASSWORD
echo
read -p "Correo electrónico del administrador: " ADMIN_EMAIL
read -p "Nombre de la red Docker: " DOCKER_NETWORK
read -p "Ubicación donde se creará el proyecto (ruta absoluta): " PROJECT_LOCATION
read -p "Nombre del proyecto (carpeta y Docker): " PROJECT_NAME
read -p "Usuario del sistema que tendrá permisos sobre el proyecto: " SYSTEM_USER

# Crear el directorio del proyecto
mkdir -p "$PROJECT_LOCATION/$PROJECT_NAME"
cd "$PROJECT_LOCATION/$PROJECT_NAME" || exit

# Establecer permisos
sudo chown -R "$SYSTEM_USER":"$(id -gn $SYSTEM_USER)" "$PROJECT_LOCATION/$PROJECT_NAME"
sudo find "$PROJECT_LOCATION/$PROJECT_NAME" -type d -exec chmod 755 {} \;
sudo find "$PROJECT_LOCATION/$PROJECT_NAME" -type f -exec chmod 644 {} \;

# Crear archivos necesarios
cat > docker-compose.yml <<EOL
version: '3.8'

services:
  db:
    image: postgres:16
    environment:
      POSTGRES_DB: $DB_NAME
      POSTGRES_USER: $SYSTEM_USER
      POSTGRES_PASSWORD: $DB_PASSWORD
    volumes:
      - postgres_data:/var/lib/postgresql/data/
    networks:
      - $DOCKER_NETWORK

  pgadmin:
    image: dpage/pgadmin4
    environment:
      PGADMIN_DEFAULT_EMAIL: $ADMIN_EMAIL
      PGADMIN_DEFAULT_PASSWORD: $DB_PASSWORD
    ports:
      - "8080:80"
    depends_on:
      - db
    networks:
      - $DOCKER_NETWORK

  web:
    build: .
    command: python manage.py runserver 0.0.0.0:8000
    volumes:
      - .:/app
    ports:
      - "8000:8000"
    depends_on:
      - db
    networks:
      - $DOCKER_NETWORK

volumes:
  postgres_data:

networks:
  $DOCKER_NETWORK:
EOL

cat > Dockerfile <<EOL
FROM python:3.9

ENV PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt /app/

RUN pip install --no-cache-dir -r requirements.txt

COPY . /app/
EOL

cat > requirements.txt <<EOL
Django>=4.2,<4.3
psycopg2-binary>=2.8
EOL

# Descargar imagen de Python
docker pull python:3.9

# Inicializar proyecto Django
docker-compose run web django-admin startproject $PROJECT_NAME .

# Configurar la base de datos en settings.py
SETTINGS_FILE="$PROJECT_NAME/settings.py"

# Utilizar un script Python para modificar settings.py
python3 << END
import os

settings_file = '$SETTINGS_FILE'

with open(settings_file, 'r') as file:
    lines = file.readlines()

with open(settings_file, 'w') as file:
    skip_database = False
    for line in lines:
        # Reemplazar ALLOWED_HOSTS
        if line.strip().startswith('ALLOWED_HOSTS'):
            file.write("ALLOWED_HOSTS = ['*']\n")
        # Reemplazar DATABASES
        elif line.strip().startswith('DATABASES = {'):
            file.write("DATABASES = {\n")
            file.write("    'default': {\n")
            file.write("        'ENGINE': 'django.db.backends.postgresql',\n")
            file.write("        'NAME': '$DB_NAME',\n")
            file.write("        'USER': '$SYSTEM_USER',\n")
            file.write("        'PASSWORD': '$DB_PASSWORD',\n")
            file.write("        'HOST': 'db',\n")
            file.write("        'PORT': '5432',\n")
            file.write("    }\n")
            file.write("}\n")
            skip_database = True
        elif skip_database:
            if line.strip() == '':
                skip_database = False
            continue
        else:
            file.write(line)
END

# Construir y levantar contenedores
docker-compose up -d --build

# Ejecutar migraciones y crear superusuario
docker-compose exec web python manage.py migrate

echo "Por favor, introduce las credenciales para el superusuario de Django:"
docker-compose exec web python manage.py createsuperuser
