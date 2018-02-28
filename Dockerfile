# Dockerizing base image for eXo Platform with:
#
# - Libre Office
# - eXo Platform Community

# Build:    docker build -t exoplatform/exo-community .
#
# Run:      docker run -p 8080:8080 exoplatform/exo-community
#           docker run -d -p 8080:8080 exoplatform/exo-community
#           docker run -d --rm -p 8080:8080 -v exo_data:/srv/exo exoplatform/exo-community
#           docker run -d -p 8080:8080 -v $(pwd)/setenv-customize.sh:/opt/exo/bin/setenv-customize.sh:ro exoplatform/exo-community

#FROM    exoplatform/base-jdk:jdk8
#FROM    ubuntu:16.04
#FROM    ubuntu:14.04
#FROM    exoplatform/ubuntu-jdk7:7u71
FROM exoplatform/base-jdk:jdk8

LABEL   maintainer="Roman Vyhovskyi vihovskyr@gmail.com>"

# Environment variables
ENV EXO_VERSION 5.0.0-RC10
ENV MYSQL_DRIVER_VERSION 5.1.45
ENV EXO_APP_DIR   /opt/exo
ENV EXO_CONF_DIR  /etc/exo
ENV EXO_DATA_DIR  /srv/exo
ENV EXO_LOG_DIR   /var/log/exo
ENV EXO_TMP_DIR   /tmp/exo-tmp
ENV EXO_DOWNLOADS /srv/downloads
ENV EXO_LIB /opt/exo/lib/
ENV EXO_USER exo
ENV EXO_GROUP ${EXO_USER}
ENV EXO_SRC platform-community-5.1.x-SNAPSHOT

# allow to override the list of addons to package by default
#ARG ADDONS="exo-jdbc-driver-mysql:1.1.0"
#ARG ADDONS="exo-tasks--no-compat"

# Customise system
RUN rm -f /bin/sh && ln -s /bin/bash /bin/sh

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
# giving all rights to eXo user
RUN useradd --create-home --user-group --shell /bin/bash ${EXO_USER} \
    && echo "exo   ALL = NOPASSWD: ALL" > /etc/sudoers.d/exo && chmod 440 /etc/sudoers.d/exo

# Install Java Environment
RUN apt-get update -y \
  && apt-get -qq -y upgrade \
#  && apt-get install software-properties-common -y \
#  && add-apt-repository ppa:webupd8team/java -y \
#  && apt-get update -y \
#  && echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | debconf-set-selections \
#  && echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 seen true" | debconf-set-selections \
#  && apt-get install oracle-java8-installer -y \
#  && apt-get install oracle-java8-set-default -y \
#  && apt-get install curl -y \
#  && apt-get install unzip -y \
  && apt-get -qq -y install -y xmlstarlet \
  && apt-get -qq -y autoremove \
  && apt-get -qq -y clean \
  && rm -rf /var/lib/apt/lists/*

# Create needed directories
RUN mkdir -p ${EXO_DATA_DIR}   && chown ${EXO_USER}:${EXO_GROUP} ${EXO_DATA_DIR} \
    && mkdir -p ${EXO_TMP_DIR} && chown ${EXO_USER}:${EXO_GROUP} ${EXO_TMP_DIR} \
    && mkdir -p ${EXO_LOG_DIR} && chown ${EXO_USER}:${EXO_GROUP} ${EXO_LOG_DIR} \
    && mkdir -p ${EXO_DOWNLOADS} && chown ${EXO_USER}:${EXO_GROUP} ${EXO_DOWNLOADS} \
    && mkdir -p ${EXO_LIB} && chown ${EXO_USER}:${EXO_GROUP} ${EXO_LIB} \ 
	&& mkdir -p ${EXO_APP_DIR}/bin && chown ${EXO_USER}:${EXO_GROUP} ${EXO_APP_DIR}/bin

#HTTP old mirros
# http://10.23.9.44/dashboard/phpinfo.php
# Install eXo Platform SRC

#Copy sources
COPY src/src.zip srv/downloads
RUN mv srv/downloads/src.zip srv/downloads/${EXO_SRC}.zip

#RUN cd srv/downloads / && ls

RUN unzip -q /srv/downloads/${EXO_SRC}.zip -d /srv/downloads/ \
    && rm -f /srv/downloads/${EXO_SRC}.zip \
    && chown ${EXO_USER}:${EXO_GROUP} srv/downloads/${EXO_SRC} \ 
    && chmod -R 777 srv/downloads/${EXO_SRC} \ 
	&& mv -v /srv/downloads/${EXO_SRC}/* ${EXO_APP_DIR} \
    && chown -R ${EXO_USER}:${EXO_GROUP} ${EXO_APP_DIR} \
    && ln -s ${EXO_APP_DIR}/gatein/conf /etc/exo \
    && rm -rf ${EXO_APP_DIR}/logs && ln -s ${EXO_LOG_DIR} ${EXO_APP_DIR}/logs

#Add mysql mysql JDBC/JNDI driver
RUN curl -L -o /srv/downloads/mysql-jdbc-${MYSQL_DRIVER_VERSION}.zip https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${MYSQL_DRIVER_VERSION}.zip && \
	unzip -q /srv/downloads/mysql-jdbc-${MYSQL_DRIVER_VERSION}.zip -d /srv/downloads && \
	cp -v /srv/downloads/mysql-connector-java-${MYSQL_DRIVER_VERSION}/mysql-connector-java-${MYSQL_DRIVER_VERSION}-bin.jar ${EXO_APP_DIR}/lib/
#RUN cd srv/downloads / && ls

#Add marinaDB mysql JDBC/JNDI driver
RUN curl -L -o /srv/downloads/mariadb-java-client-2.2.2.jar https://downloads.mariadb.com/Connectors/java/connector-java-2.2.2/mariadb-java-client-2.2.2.jar 
#RUN cd srv/downloads / && ls
#RUN unzip -q /srv/downloads/mariadb-java-client-2.2.2.jar.zip -d /srv/downloads && 
#RUN cd srv/downloads / && ls
RUN cp -v /srv/downloads/mariadb-java-client-2.2.2.jar ${EXO_APP_DIR}/lib/

#RUN cd ${EXO_APP_DIR} \  && ls	\ cd / \
#    $$ cd ${EXO_DATA_DIR} \  && ls	

#Create server presets
COPY conf/server.xml ${EXO_APP_DIR}/conf/server.xml
#COPY conf/setenv.sh ${EXO_APP_DIR}/bin/

#RUN echo "JAVA_OPTS=\"-Dmysql.host=\$MYSQL_HOST -Dmysql.database=\$MYSQL_DATABASE -Dmysql.user=\$MYSQL_USER -Dmysql.password=\$MYSQL_PASSWORD \$JAVA_OPTS\"" >> ls \ && ${EXO_APP_DIR}/bin/setenv.sh && \
#        rm -rf ${EXO_APP_DIR}/logs && ln -s ${EXO_LOG_DIR} ${EXO_APP_DIR}/logs && \
#        chown -R ${EXO_USER}:${EXO_GROUP} ${EXO_APP_DIR}

#SET standart environment
RUN chmod 777 ${EXO_APP_DIR}/bin/setenv.sh
RUN ${EXO_APP_DIR}/bin/setenv.sh

# Install Docker customization file
#ADD scripts/setenv-docker-customize.sh ${EXO_APP_DIR}/bin/setenv-docker-customize.sh
#RUN chmod 755 ${EXO_APP_DIR}/bin/setenv-docker-customize.sh \
#    && chown ${EXO_USER}:${EXO_USER} ${EXO_APP_DIR}/bin/setenv-docker-customize.sh \
#    && sed -i '/# Load custom settings/i \
#\# Load custom settings for docker environment\n\
#[ -r "$CATALINA_BASE/bin/setenv-docker-customize.sh" ] && { \n\
#  source $CATALINA_BASE/bin/setenv-docker-customize.sh \n\
#  if [ $? != 0 ]; then \n\
#    echo "Problem during docker customization process ... startup aborted !" \n\
#    exit 1 \n\
#  fi \n\
#} || echo "No Docker eXo Platform customization file : $CATALINA_BASE/bin/setenv-docker-customize.sh"\n\
#' ${EXO_APP_DIR}/bin/setenv.sh \
#  && grep 'setenv-docker-customize.sh' ${EXO_APP_DIR}/bin/setenv.sh

# allow to override the list of addons to package by default
#ARG ADDONS="exo-jdbc-driver-mysql:1.1.0"
#ARG ADDON="exo-tasks:--no-compat"
#RUN /opt/exo/addon install exo-tasks --no-compat

COPY scripts/wait-for-it.sh /opt/wait-for-it.sh
RUN chmod 755 /opt/wait-for-it.sh \
    && chown ${EXO_USER}:${EXO_GROUP} /opt/wait-for-it.sh

EXPOSE 8080 
USER ${EXO_USER}

WORKDIR "/opt/exo/"
VOLUME ["/srv/exo"]

#RUN for a in ${ADDONS}; do echo "Installing addon $a"; /opt/exo/addon install $a; done

#RUN chmod +x /opt/exo/start_eXo.sh
ENTRYPOINT ["/opt/exo/start_eXo.sh", "--data", "/srv/exo"]
