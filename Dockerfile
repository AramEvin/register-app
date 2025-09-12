FROM tomcat:9.0.109-jdk21-corretto
RUN cp -R  /usr/local/tomcat/webapps.dist/*  /usr/local/tomcat/webapps
COPY /webapp/target/*.war /usr/local/tomcat/webapps

