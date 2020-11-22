
#!/usr/bin/env bash

DBNAME=wordpress_db
DBUSER=keepcoding
DBPASSWD=keepcoding

apt-get update
apt-get install vim curl git nginx -y

# install java 8
sudo apt-get install default-jre -y

################################################################

#Instalar logstash
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list

sudo apt-get update && sudo apt-get install logstash -y
sudo systemctl enable logstash
sudo systemctl start logstash

# configure logstash to be available on port 5044 and send to elasticsearch
sudo chmod 777 /etc/logstash
sudo touch /etc/logstash/conf.d/ex-pipeline.conf
sudo cat << EOF > /etc/logstash/conf.d/ex-pipeline.conf
input {
  beats {
    host => "10.0.15.30"
    port => "5044"
  }
}
output {
  elasticsearch {
    hosts => [ "10.0.15.30:9200" ]
  }
}
EOF

service logstash restart

################################################################

#Instalar elasticsearch
sudo apt-get update && sudo apt-get install elasticsearch -y

# Configurar elasticsearch.
# sed -i 's/#network.host: 192.168.0.1/#network.host: 10.0.15.30/g' /etc/elasticsearch/elasticsearch.yml
# sudo systemctl start elasticsearch
# sudo systemctl enable elasticsearch

# configure elasticsearch to be available on port 9200
sudo chmod 777 /etc/elasticsearch
sudo touch /etc/elasticsearch/elasticsearch.yml
sudo cat << EOF > /etc/elasticsearch/elasticsearch.yml
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: 10.0.15.30
http.port: 9200-9300
EOF
sudo service elasticsearch restart
# available on startup
update-rc.d elasticsearch defaults 95 10

################################################################

#Instalar Kibana
sudo apt-get install kibana -y

# configure kibana to be available on port 5601 and connect to elasticsearch instance
sudo  chmod 777 /etc/kibana
sudo touch /etc/kibana/kibana.yml
sudo cat << EOF > /etc/kibana/kibana.yml
server.port: 5601
server.host: 10.0.15.30
elasticsearch.url: http://10.0.15.30:9200
EOF

sudo service kibana restart

# available on startup
sudo update-rc.d kibana defaults 95 10
# sudo systemctl enable kibana
# sudo systemctl start kibana
