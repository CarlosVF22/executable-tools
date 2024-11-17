#!/bin/bash

# Colores para mejor visualización
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Iniciando instalación de NVM y Node.js...${NC}"

# Verificar si nvm ya está instalado
if [ -d "$HOME/.nvm" ]; then
    echo -e "${YELLOW}NVM ya está instalado. Actualizando...${NC}"
    source ~/.nvm/nvm.sh
    nvm --version
else
    # Instalar dependencias necesarias
    echo -e "${GREEN}Instalando dependencias...${NC}"
    sudo apt-get update
    sudo apt-get install -y curl build-essential

    # Descargar e instalar NVM
    echo -e "${GREEN}Descargando e instalando NVM...${NC}"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

    # Cargar NVM en la sesión actual
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
fi

# Verificar la instalación de NVM
if ! command -v nvm &> /dev/null; then
    echo -e "${RED}Error: NVM no se instaló correctamente${NC}"
    exit 1
fi

# Obtener las últimas 5 versiones LTS de Node.js
echo -e "${GREEN}Obteniendo las últimas versiones LTS de Node.js...${NC}"
versions=($(nvm ls-remote --lts | grep "v[0-9]" | tail -n 5))

if [ ${#versions[@]} -eq 0 ]; then
    echo -e "${RED}Error: No se pudieron obtener las versiones de Node.js${NC}"
    exit 1
fi

# Mostrar menú de selección
echo -e "${GREEN}Seleccione la versión de Node.js a instalar:${NC}"
select version in "${versions[@]}"; do
    if [ -n "$version" ]; then
        echo -e "${GREEN}Instalando Node.js $version...${NC}"
        nvm install "$version"
        nvm use "$version"
        nvm alias default "$version"
        
        # Verificar la instalación
        node_version=$(node --version)
        npm_version=$(npm --version)
        
        echo -e "${GREEN}Instalación completada:${NC}"
        echo -e "Node.js: $node_version"
        echo -e "NPM: $npm_version"
        
        # Agregar NVM al archivo de perfil si no existe
        if ! grep -q "NVM_DIR" ~/.bashrc; then
            echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc
            echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc
            echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.bashrc
        fi
        
        break
    else
        echo -e "${RED}Selección inválida${NC}"
    fi
done

echo -e "${GREEN}¡Instalación completada exitosamente!${NC}"
echo -e "${YELLOW}Por favor, reinicie su terminal o ejecute: source ~/.bashrc${NC}"