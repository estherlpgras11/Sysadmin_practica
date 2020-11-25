
#!/usr/bin/env bash

apt-get update
apt-get install curl nginx  -y

# install java 8
sudo apt-get install default-jre -y



################################################################ ELASTICSEARCH
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt-get install apt-transport-https -y
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
sudo apt-get update && sudo apt-get -y install elasticsearch

sudo rm /etc/elasticsearch/elasticsearch.yml
sudo cp /vagrant/elasticsearch.yml /etc/elasticsearch

sudo /bin/systemctl enable elasticsearch
sudo systemctl restart elasticsearch

################################################################  LOGSTASH
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt-get install apt-transport-https -y
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
sudo apt-get update && sudo apt-get install logstash -y

# Configure logstash to be available on port 5044 and send to elasticsearch 9200:
sudo touch /etc/logstash/conf.d/02-beats-input.conf
sudo cat > /etc/logstash/conf.d/02-beats-input.conf <<EOF
input {
  beats {
    port => "5044"
  }
}
EOF

sudo touch /etc/logstash/conf.d/30-elasticsearch-output.conf
sudo cat > /etc/logstash/conf.d/30-elasticsearch-output.conf <<EOF
output {
  elasticsearch {
    hosts => [ "localhost:9200" ]
  }
}
EOF

sudo systemctl restart logstash
sudo systemctl enable logstash

################################################################ KIBANA
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt-get install apt-transport-https -y
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
sudo apt-get update && sudo apt-get -y install kibana

sudo rm /etc/kibana/kibana.yml
sudo cp /vagrant/kibana.yml /etc/kibana

sudo systemctl start kibana
sudo systemctl enable kibana

################################################################ NGINX

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
