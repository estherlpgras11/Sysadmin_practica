# Documentación técnica para la práctica del módulo Sysadmin Administración de redes y sistemas
Full Stack DevOps Bootcamp III

Noviembre 2020

git clone https://gitlab.keepcoding.io/Kainight/sysadmin_practica.git


# Definiciones y especificación de requerimientos
El objetivo final de la práctica será la implementación de una herramienta de gestión de logs unificada  basándonos en el stack ELK (Elasticsearch, Logstash, Kibana).

* Logstash, se encarga de analizar registros que se reciben, para parsearlos y separarlos en campos. Una vez parseados los envía a un output que en nuestro caso será Elasticsearch.
* Elasticsearch es un tipo de Base de Datos optimizada para la gestión de documentos y la búsqueda en ellos. Una vez recibe el documento desde Logstash lo procesa e indexa.
* Kibana nos permite visualizar los datos y crear dashboards.

Para enviar los datos montamos otro stack, en el que instalaremos un servicio web (Wordpress, en este caso) y una base de datos MySQL sobre un servidor Linux. Instalaremos además un servicio encargado de enviar logs de la BBDD y del servidor web (apache) al logstash -> En este caso, usaremos Filebeat.



# Arquitectura de la infraestructura

															 vagrant
															    .
															    .
				 VM Ubuntu (ubuntu 16.04) ...................................................... VM ELK (ubuntu 16.04)
						 .																			.
						 .																			.
			.........................................												... Elasticsearch
			.			 .            .				.												.	
			.			 .			  .				.												.
			.			 .			  . 			.					beats						.
		  MySQL	   	   Apache	  Wordpress		 Filebeat ----------------------------------------> ................Lostash
																									.
																									.
																									......................Kivana
																									.
																									.
																								  Nginx


# Setup de la VM Ubuntu y VM ELK

## VM ELK. Usamos el box ubuntu/xenial64 para levantar una máquina con ubuntu 16.04, usando virtualbox como provider. Mapeamos los puertos en los que escucharan los servicios ELK. Realizamos el aprovisionamiento a través de "ELK_configure.sh", que contiene el scritping necesario para automatizar la instalación y configuración del stack.

## VM Ubuntu. Usamos el box ubuntu/xenial64 para levantar una máquina con ubuntu 16.04, usando virtualbox como provider. Mapeamos el puerto 80 del guest al puerto 8000 del host para poder ver el wordpress en nuestra máquina física cuando esté levantado. Realizamos el aprovisionamiento a través de "bootstrap.sh", que contiene el scritping necesario para automatizar la instalación y configuración del wordpress y sus dependencias. 	

Compartimos la carpeta en la que se encuentra el Vagrantfile con ambas máquinas, en el directorio /vagrant, para poder guardar ahí los archivos .yml y editarlos desde el host. Esto lo hacemos una vez están los servicios arrancados en ambas máquinas, entrando mediante ssh y moviendo los archivos "filebeat.yml", "elasticsearch.yml" y "kibana.yml" al directorio /vagrant. Los editamos en local para realizar las configuraciones correspondientes y luego reemplazamos los archivos originales por los modificados.



# Documentación de la instalación de servicios de la VM ELK			

Intalamos el nginx para realizar el enrutamiento de puerto, y el Java para poder arrancar el Elasticsearh, que requiere al menos Java 8 para funcionar.

## Para instalar el stack ELK, nos decargamos la Public Signing Key y guardamos el repositorio en /etc/apt/sources.list.d/elastic-7.x.list. Una vez hecho esto, ya podemos  instalar el Logstash, el Elasticsearch y el Kibana mediante APT. 
Para realizar las configuraciones de cada servicio arrancamos la máquina y accedemos a los directorios  /etc/elasticsearch  y  /etc/kibana, copiamos los .yml de cada directorio (elasticsearch.yml  y  kibana.yml) y los colocamos en el directorio /vagrant. De este modo, podremos editar los ficheros en local. (Previamente había intentado editarlos directamente mediante sed, pero me daba problemas por que no respetaba las indexaciones del yaml).

### Elasticsearch: 
1- Modificamos el .yml en el apartado Network, de modo que http.port señale al puerto 9200 (elasticsearh) y el network.host sea localhost.
2- Reemplazamos el .yml original por el que hemos modificado.
3- Habilitamos y reiniciamos el servicio para aplicar los cambios.

### Logstash: 
1- Creamos el fichero de configuración para el input, donde señalamos el tipo de input  (beats, en este caso)  y  el puerto  por el que los tiene que recibir, en este caso el 5044.
2- Creamos el fichero de configuración para realizar un filtro de los logs del wordpress.
3- Creamos el fichero de configuración para el output, donde señalamos que tiene que enviar los logs parseados al elasticsearch, indicando el host y el  puerto correspondientes según el .yml del  elasticsearch (localhost:9200).  Además, indicamos al  Losgstash  que indexe los logs en el Elasticsearch: %{[@metadata][beat]} indica en la primera parte del indice el valor del campo de metadatos del beat, y %{[@metadata][version]} indica en la segunda parte la versión del beat.
4- Iniciamos y habilitamos el servicio.

### Kibana:
1- Modificamos el kibana.yml: 
	a) Especificamos el puerto que usará el servidor, en este caso el 5601 (que tenemos redireccionado al puerto 5600 de nuesto host).
	b) Modificamos el server.host a "0.0.0.0" para permitir la conexión desde usuarios remotos. 	
	c) Señalamos en elasticsearch.hosts: ["http://localhost:9200"] la URL de la instancia de Elasticsearch que se utilizará para todas las queries (consultas). 
	d) Por últitmo, habilitamos el logging.verbose: true para registrar todos los logs, incluida la información de uso del sistema y todas las solicitudes.
2- Reemplazamos el .yml original por el que hemos modificado.
3- Iniciamos y habilitamos el servicio.

## Instalamos Nginx y creamos un proxy para el enrutamiento de puertos.
1- Creamos fichero de configuraciones del proxy para el enrutado dentro del directorio /etc/nginx/sites-available/ y lo nombramos la ip de la máquina: 10.0.15.31
2- Configuramos el fichero para redireccionar el puerto 5601 al 5600 (kibana) y el del puerto 9201 al 9200 (elasticsearch).
3- Indicamos al Nginx que utilica el fichero de configuraciones creado para el proxy.
4- Reiniciamos Nginx para que aplique las configuraciones del proxy.



# Documentación de la instalación de servicios de la VM Ubuntu	

## Intalación y configuración de MYSQL
1- Definimos las variables de la base de datos: nombre de la base de datos, usuario y password
2- Seteamos los datos de acceso en el archivo de configuraciones.
3- Instalamos MYSQL y PHP mediante APT
4- Creamos y configuramos la BBDD en el servidor y le asignamos permisos y privilegios al usuario/BBDD creados.
5- Iniciamos el mysql

## Intalación y configuración del Apache
1- Instalamos Apache mediante APT
2- Configuramos la redirección del wordpress mediante alias: para ello creamos un fichero de redirección dentro del directorio etc/apache2/sites-available/ al que nombramos wordpress.conf indicando el alias /blog para acceder a los directorios /usr/share/wordpress (site) y /usr/share/wordpress/wp-conternt (admin)
3- Reiniciamos apache para aplicar las nuevas configuraciones.

## Instalación y configuración de Wordpress
1- Instalamos wordpress
2- Configuramos wordpress para que use la BBDD creada con anterioridad: para ello crearemos un fichero de configuración dentro del directorio /etc/wordpress/ al que nombramos con la ip de la máquina: config-10.0.15.30.php
3- Reiniciamos el wordpress y refrescamos el apache.

## Instalación y configuración de Filebeat
1- Para instalar Filebeat, nos decargamos la Public Signing Key y guardamos el repositorio en /etc/apt/sources.list.d/elastic-7.x.list. Una vez hecho esto, ya podemos  instalar Filebeat mediante APT. Copiamos el filebeat.yml del servidor y los colocamos en el directorio /vagrant. De este modo, podremos editar los ficheros en local.
2- Modificamos el fichero filebeat.yml:
	a) Habilitamos los logs: filebeat.inputs type log enable.
	b) Definimos la ubicación (path) donde están los logs a enviar. 
	c) Comentamos las líneas del output.elasticsearch para deshabilitar esta opción, ya que enviaremos los logs al logstash.
	d) Descomentamos la línea output.logstash y configuramos el hosts: ["10.0.15.31:5044"] para enviar los logs al logstash de la VM ELK
3- Reemplazamos el .yml original por el que hemos modificado.
4- Cargamos el index template en el Elasticsearch manualmente.
5- Habilitamos los módulos apache y mysql de filibeat
6- Arrancamos y habilitamos filebeat.

___________________
#Autor: 
Esther López
