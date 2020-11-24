
#!/usr/bin/env bash

apt-get update
apt-get install curl nginx  -y

# install java 8
sudo apt-get install default-jre -y 2>/dev/null


################################################################ INSTALL  ELK

#Instalar stack ELK elasticsearch
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt-get install apt-transport-https -y 2>/dev/null
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
sudo apt-get update && sudo apt-get -y install elasticsearch && sudo apt-get -y install logstash && sudo apt-get -y install kibana



################################################################ ELASTICSEARCH

# sudo sed -i '55 c\ network.host: localhost' /etc/elasticsearch/elasticsearch.yml
# sudo sed -i '59 c\ http.port: 9200' /etc/elasticsearch/elasticsearch.yml

# Configurar elasticsearch  to be available on port 9200 
sudo cat  > /etc/elasticsearch/elasticsearch.yml << EOF
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: localhost
http.port: 9200
EOF

sudo /bin/systemctl enable elasticsearch
sudo systemctl restart elasticsearch

################################################################  LOGSTASH

# Configure logstash to be available on port 5044 and send to elasticsearch 9200:

sudo cat > /etc/logstash/conf.d/02-beats-input.conf <<EOF
input {
  beats {
    port => 5044
    host => "0.0.0.0"
  }
}

output {
  elasticsearch {
    hosts => [ "localhost:9200" ]
    manage_template => false
    index => "%{[@metadata][beat]}-%{[@metadata][version]}" 
    document_type => "%{[@metadata][type]}"
  }
}
EOF

sudo systemctl restart logstash
sudo systemctl enable logstash

################################################################ KIBANA

# Configure kibana to be available on port 5601 and connect to elasticsearch instance 9200
# sudo cat << EOF > /etc/kibana/kibana.yml
# server.port: 5601
# server.host: "0.0.0.0"
# elasticsearch.hosts: ["http://10.0.15.31:9200"]
# EOF

sudo sed -i '2 c\ server.port: 5601' /etc/kibana/kibana.yml
sudo sed -i '7 c\ server.host: "0.0.0.0"' /etc/kibana/kibana.yml
sudo sed -i '28 c\ elasticsearch.hosts: ["http://localhost:9200"]' /etc/kibana/kibana.yml
sudo sed -i '37 c\ kibana.index: ".kibana_1"' /etc/kibana/kibana.yml

sudo systemctl restart kibana
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

EOF

sudo ln -s /etc/nginx/sites-available/10.0.15.31 /etc/nginx/sites-enabled/10.0.15.31
sudo systemctl restart nginx

