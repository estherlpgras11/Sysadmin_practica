
#!/usr/bin/env bash

apt-get update
apt-get install curl nginx -y

# install java 8
sudo apt-get install default-jre -y

################################################################

#Instalar elasticsearch

wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-6.x.list

sudo apt-get update && sudo apt-get install -y elasticsearch 

#sudo chmod 777 /etc/elasticsearch
# sudo cat  > /etc/elasticsearch/elasticsearch.yml << EOF
# path.data: /var/lib/elasticsearch
# path.logs: /var/log/elasticsearch
# network.host: localhost
# http.port: 9200
# EOF

sudo systemctl start elasticsearch
sudo systemctl enable elasticsearch


# available on startup
#update-rc.d elasticsearch defaults 95 10

################################################################

#Instalar Kibana
sudo apt-get install -y kibana 

sudo systemctl enable kibana
sudo systemctl start kibana

#Crear proxy enrutamiento
sudo cat > /etc/nginx/sites-available/10.0.15.31 << EOF
server {
    listen 5600;

    server_name 10.0.15.31;

    location / {
        proxy_pass http://localhost:5601;
        proxy_http_version 1.1;
        proxy_set_header Upgrade '$http_upgrade';
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host '$host';
        proxy_cache_bypass '$http_upgrade';
    }
}
server {
    listen 9201;

    server_name 10.0.15.31;

    location / {
        proxy_pass http://localhost:9200;
        proxy_http_version 1.1;
        proxy_set_header Upgrade '';
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host '';
        proxy_cache_bypass '';
    }
}
server {
    listen 5045;

    server_name 10.0.15.31;

    location / {
        proxy_pass http://localhost:5044;
        proxy_http_version 1.1;
        proxy_set_header Upgrade '';
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host '';
        proxy_cache_bypass '';
    }
}

EOF

sudo ln -s /etc/nginx/sites-available/10.0.15.31 /etc/nginx/sites-enabled/10.0.15.31

sudo systemctl restart nginx




################################################################

#Instalar logstash

sudo apt-get update && sudo apt-get install logstash -y
sudo systemctl enable logstash
sudo systemctl start logstash

# configure logstash to be available on port 5044 and send to elasticsearch
sudo touch /etc/logstash/conf.d/ex-pipeline.conf
sudo cat  > /etc/logstash/conf.d/ex-pipeline.conf << EOF
input {
  beats {
    host => "0.0.0.0"
    port => "5045"
  }
}
output {
  elasticsearch {
    hosts => [ "localhost:9200" ]
  }
}
EOF

# service logstash restart
