
#!/usr/bin/env bash


################################################ MYSQL ########################################################  

# Definimos variables:
DBNAME=wordpress_db
DBUSER=keepcoding
DBPASSWD=keepcoding

# Indicamos qué password vamos a utilizar para el MySQL:
apt-get update
debconf-set-selections <<< "mysql-server mysql-server/root_password password $DBPASSWD"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DBPASSWD"

# Instalamos el MySQL:
sudo apt-get update
sudo apt-get -y install mysql-server php php-mysql

# Creamos una DB:
mysql -uroot -p$DBPASSWD -e "CREATE DATABASE $DBNAME"
mysql -uroot -p$DBPASSWD -e "grant all privileges on $DBNAME.* to '$DBUSER'@'%' identified by '$DBPASSWD'"
mysql -uroot -p$DBPASSWD -e "FLUSH PRIVILEGES"

# Modificamos el arcivo mysqld.cnf para permitir el acceso remoto a la DB:
sudo sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
sudo service mysql restart
sudo service mysql start -y


################################################ APACHE #########################################################  

apt-get -y install apache2 libapache2-mod-php php-curl php-gd php-gettext

#Configuración del wordpress en el apache
cat > /etc/apache2/sites-available/wordpress.conf <<EOF
Alias /blog /usr/share/wordpress
<Directory /usr/share/wordpress>
    Options FollowSymLinks
    AllowOverride Limit Options FileInfo
    DirectoryIndex index.php
    Order allow,deny
    Allow from all
</Directory>
<Directory /usr/share/wordpress/wp-content>
    Options FollowSymLinks
    Order allow,deny
    Allow from all
</Directory>
EOF

sudo chown -R www-data:www-data /var/www/html
sudo service apache2 reload -y


############################################### WORDPRESS #######################################################  

# Instalamos el Wordpress:
sudo apt-get -y install wordpress 

# Configuramos el Wordpress para que use la DB y habilitamos el
cat > /etc/wordpress/config-10.0.15.30.php <<EOF
<?php
define('DB_NAME', '$DBNAME');
define('DB_USER', '$DBUSER');
define('DB_PASSWORD', '$DBPASSWD');
define('DB_HOST', '10.0.15.30');
define('DB_COLLATE', 'utf8_general_ci');
define('WP_CONTENT_DIR', '/usr/share/wordpress/wp-content');
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
define('WP_DEBUG_DISPLAY', false);
?>
EOF

sudo a2ensite wordpress
sudo service apache2 reload -y

############################################### FILEBEAT ########################################################  

# Instalamos el Filebeat
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo apt-get update && sudo apt-get install -y filebeat

# Eliminamos el .yml original y lo substituimos por el que se encuentra en /vagrant para deshabilitar el output de elasticsearch y habilitar el del logstach.
sudo rm /etc/filebeat/filebeat.yml
sudo cp /vagrant/filebeat.yml /etc/filebeat

# Cargamos el index template en el Elasticsearch manualmente:
sudo filebeat setup --index-management -E output.logstash.enabled=false -E 'output.elasticsearch.hosts=["10.0.15.31:9201"]'
sudo filebeat setup -e -E output.logstash.enabled=false -E output.elasticsearch.hosts=['10.0.15.31:9201'] -E setup.kibana.host=10.0.15.31:5601

# Habilitamos los modulos apache y mysql 
sudo filebeat modules enable apache mysql

# Reiniciamos
sudo systemctl start filebeat
sudo systemctl enable filebeat

