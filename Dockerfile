FROM openjdk:8-alpine

# Configuration variables.
ENV JIRA_HOME     /var/atlassian/jira
ENV JIRA_INSTALL  /opt/atlassian/jira
ENV JIRA_VERSION  8.2.0

ENV JIRA_USER jira 
ENV JIRA_GROUP jira 
ENV JVM_MINIMUM_MEMORY 2G 
ENV JVM_MAXIMUM_MEMORY 10G
ENV JIRA_SESSION_TIMEOUT 60


#create user if not exist
RUN set -eux; \
	getent group ${JIRA_GROUP} || addgroup -S ${JIRA_GROUP}; \
	getent passwd ${JIRA_USER} || adduser -S ${JIRA_USER} ${JIRA_GROUP};

# Install Atlassian JIRA and helper tools and setup initial home
# directory structure.
RUN set -x \
    && apk add --no-cache curl xmlstarlet bash ttf-dejavu libc6-compat dos2unix \
    && mkdir -p                				"${JIRA_HOME}" \
    && mkdir -p                				"${JIRA_HOME}/caches/indexes" \
    && chmod -R 700            				"${JIRA_HOME}" \
    && chown -R ${JIRA_USER}:${JIRA_GROUP}  "${JIRA_HOME}" \
    && mkdir -p                				"${JIRA_INSTALL}/conf/Catalina" \
    && curl -Ls                				"https://www.atlassian.com/software/jira/downloads/binary/atlassian-jira-software-${JIRA_VERSION}.tar.gz" | tar -xz --directory "${JIRA_INSTALL}" --strip-components=1 --no-same-owner \
	&& rm -f                   				"${JIRA_INSTALL}/lib/postgresql-9.1-903.jdbc4-atlassian-hosted.jar" \
    && curl -Ls                				"https://jdbc.postgresql.org/download/postgresql-42.2.5.jar" -o "${JIRA_INSTALL}/lib/postgresql-42.2.5.jar" \
    && chmod -R 700            				"${JIRA_INSTALL}/conf" \
    && chmod -R 700            				"${JIRA_INSTALL}/logs" \
    && chmod -R 700            				"${JIRA_INSTALL}/temp" \
    && chmod -R 700            				"${JIRA_INSTALL}/work" \
    && chown -R ${JIRA_USER}:${JIRA_GROUP}	"${JIRA_INSTALL}/conf" \
    && chown -R ${JIRA_USER}:${JIRA_GROUP}	"${JIRA_INSTALL}/logs" \
    && chown -R ${JIRA_USER}:${JIRA_GROUP}	"${JIRA_INSTALL}/temp" \
    && chown -R ${JIRA_USER}:${JIRA_GROUP}	"${JIRA_INSTALL}/work" \
    && sed --in-place          				"s/java version/openjdk version/g" "${JIRA_INSTALL}/bin/check-java.sh" \
    && echo -e                 				"\njira.home=$JIRA_HOME" >> "${JIRA_INSTALL}/atlassian-jira/WEB-INF/classes/jira-application.properties" \
    && touch -d "@0"           				"${JIRA_INSTALL}/conf/server.xml" \
    && sed -i								"s/<session-timeout>.*<\/session-timeout>/<session-timeout>${JIRA_SESSION_TIMEOUT}<\/session-timeout>/g" "${JIRA_INSTALL}/atlassian-jira/WEB-INF/web.xml" \
	&& sed -i 								"s/JIRA=.*\n/JIRA=${JIRA_USER}\n/g" "${JIRA_INSTALL}/bin/user.sh" \
	&& sed -i 								"s/JVM_MINIMUM_MEMORY=.*\n/JVM_MINIMUM_MEMORY=${JVM_MINIMUM_MEMORY}\n/g" "${JIRA_INSTALL}/bin/user.sh" \
	&& sed -i 								"s/JVM_MAXIMUM_MEMORY=.*\n/JVM_MAXIMUM_MEMORY=${JVM_MAXIMUM_MEMORY}\n/g" "${JIRA_INSTALL}/bin/user.sh" 
 

# Expose default HTTP connector port.
EXPOSE 8080


COPY "docker-entrypoint.sh" "/"
RUN dos2unix /docker-entrypoint.sh && apk del dos2unix

#make sure the file can be executed
RUN ["chmod", "+x", "/docker-entrypoint.sh"]

ENTRYPOINT ["/docker-entrypoint.sh"]

# 
USER ${JIRA_USER}:${JIRA_GROUP}
# Set the default working directory as the installation directory.
WORKDIR /var/atlassian/jira

# Run Atlassian JIRA as a foreground process by default.
CMD ["/opt/atlassian/jira/bin/start-jira.sh", "-fg"]