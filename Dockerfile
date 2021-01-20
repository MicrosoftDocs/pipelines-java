  
FROM ubuntu:18.04
RUN apt-get update  
RUN  apt-get -y install apache2
ADD  index.html /var/wwww/html
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf
CMD apache2ctl - D  FOREGROUND
ENTRYPOINT apache2ctl -D FOREGROUND
EXPOSE 80
