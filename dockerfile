FROM openjdk:7-jdk
MAINTAINER Manuel de la Peña <manuel.delapenya@liferay.com>

ENV DEBIAN_FRONTEND noninteractive
ENV TOMCAT_MAJOR_VERSION=8
ENV TOMCAT_VERSION=8.5.31
ENV TOMCAT_HOME=/opt/apache-tomcat-$TOMCAT_VERSION

# Install mysql-server and tomcat 8
RUN apt-get update && apt-get install -y lsb-release && \
  wget https://dev.mysql.com/get/mysql-apt-config_0.8.4-1_all.deb && \
  dpkg -i mysql-apt-config_0.8.4-1_all.deb && rm -f mysql-apt-config_0.8.4-1_all.deb && \
  mkdir -p $TOMCAT_HOME && cd /opt && \
  wget http://mirrors.koehn.com/apache/tomcat/tomcat-8/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz && \
  tar -xvf apache-tomcat-$TOMCAT_VERSION.tar.gz && rm -f apache-tomcat-$TOMCAT_VERSION.tar.gz

# Install packages
RUN apt-get update && \
  apt-get -y install mysql-server pwgen supervisor && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add image configuration and scripts
ADD start-tomcat.sh /start-tomcat.sh
ADD start-mysqld.sh /start-mysqld.sh
ADD run.sh /run.sh
RUN chmod 755 /*.sh
ADD my.cnf /etc/mysql/conf.d/my.cnf
ADD supervisord-tomcat.conf /etc/supervisor/conf.d/supervisord-tomcat.conf
ADD supervisord-mysqld.conf /etc/supervisor/conf.d/supervisord-mysqld.conf

# Remove pre-installed database
RUN rm -rf /var/lib/mysql/*

# Add MySQL utils and DB scripts
ADD create_mysql_admin_user.sh /create_mysql_admin_user.sh
ADD mysql-setup.sh /mysql-setup.sh
ADD database/db_init.sh /db_init.sh
ADD database/database-creation.sql /database-creation.sql
ADD database/fhir-2018-02-19.sql /fhir-2018-02-19.sql
ADD database/fhirdatabase.sql /fhirdatabase.sql
ADD database/truncate-tables.sql /truncate-tables.sql
RUN chmod 755 /*.sh
RUN chmod 755 /*.sql

WORKDIR $TOMCAT_HOME

# Add volumes for MySQL 
VOLUME  ["/etc/mysql", "/var/lib/mysql"]

EXPOSE 8080 3306

ENTRYPOINT ["/run.sh"]
