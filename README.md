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
				 VM 1 (ubuntu 16.04) ...................................................... VM 2 (ubuntu 16.04)
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
# Setup de las VM 1 y VM2

## VM 1. Usamos el box ubuntu/xenial64 para levantar una máquina con ubuntu 16.04, usando virtualbox como provider. Mapeamos los puertos en los que escucharan los servicios ELK. Realizamos el aprovisionamiento a través de "ELK_configure.sh", que contiene el scritping necesario para automatizar la instalación y configuración del stack.

## VM 2. Usamos el box ubuntu/xenial64 para levantar una máquina con ubuntu 16.04, usando virtualbox como provider. Mapeamos el puerto 80 del guest al puerto 8000 del host para poder ver el wordpress en nuestra máquina física cuando esté levantado. Realizamos el aprovisionamiento a través de "bootstrap.sh", que contiene el scritping necesario para automatizar la instalación y configuración del wordpress y sus dependencias. 	

Compartimos la carpeta en la que se encuentra el Vagrantfile con ambas máquinas, en el directorio /vagrant, para poder guardar ahí los archivos .yml y editarlos desde el host. Esto lo hacemos una vez están los servicios arrancados en ambas máquinas, entrando mediante ssh y moviendo los archivos "filebeat.yml", "elasticsearch.yml" y "kibana.yml" al directorio /vagrant. Los editamos en local para realizar las configuraciones correspondientes y luego reemplazamos los archivos originales por los modificados.

# Documentación de la instalación de servicios de la VM 1			



# Documentación de la instalación de servicios de la VM 2		





___________________
#Autor: 
Esther López
