#!/bin/bash

# Actualizar paquetes
sudo apt-get update

# Instalar Apache
sudo apt-get install -y apache2

# Instalar MySQL y establecer la contraseña root como '1234'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password 1234'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password 1234'
sudo apt-get install -y mysql-server

# Instalar PHP y extensiones necesarias para WordPress
sudo apt-get install -y php libapache2-mod-php php-mysql php-xml php-gd php-curl php-zip

# Reiniciar Apache para aplicar los cambios
sudo systemctl restart apache2

# Descargar y descomprimir WordPress
cd /tmp
wget https://wordpress.org/latest.tar.gz
tar -xvzf latest.tar.gz

# Mover WordPress a la carpeta de Apache
sudo rm -rf /var/www/html/*
sudo mv wordpress/* /var/www/html/

# Cambiar permisos de la carpeta de WordPress
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

# Crear base de datos para WordPress
mysql -u root -p1234 -e "CREATE DATABASE wordpress;"

# Permitir el uso de contraseñas en MySQL para root
sudo mysql -u root -p1234 -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '1234';"

# Habilitar mod_rewrite para los enlaces permanentes de WordPress
sudo a2enmod rewrite
sudo systemctl restart apache2

# Configurar Apache para WordPress
sudo bash -c 'cat << EOF > /etc/apache2/sites-available/wordpress.conf
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html
    <Directory /var/www/html/>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF'

# Habilitar el sitio de WordPress
sudo ln -s /etc/apache2/sites-available/wordpress.conf /etc/apache2/sites-enabled/
sudo systemctl restart apache2
