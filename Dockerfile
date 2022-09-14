FROM registry.access.redhat.com/ubi8/openjdk-17:1.13 AS builder
LABEL maintainer="IBM Java Engineering at IBM Cloud"
RUN yum update -y && yum upgrade -y

USER root
WORKDIR /app
COPY pom.xml .
RUN mvn -N wrapper:wrapper -Dmaven=3.8.4

COPY . /app
RUN ./mvnw install

ARG bx_dev_user=root
ARG bx_dev_userid=1000
RUN export BX_DEV_USER=$bx_dev_user
RUN export BX_DEV_USERID=$bx_dev_userid
RUN if [ $bx_dev_user != "root" ]; then useradd -ms /bin/bash -u $bx_dev_userid $bx_dev_user; fi
USER 1001

# Multi-stage build. New build stage that uses the UBI as the base image.

# In the short term, we are using the OpenJDK for UBI. Long term, we will use
# the IBM Java Small Footprint JVM (SFJ) for UBI, but that is not in public
# Docker at the moment.
# (https://github.com/ibmruntimes/ci.docker/tree/master/ibmjava/8/sfj/ubi-min)

FROM registry.access.redhat.com/ubi8/openjdk-17:1.13
RUN yum update -y && yum upgrade -y

# disable vulnerable TLS algorithms
USER root
RUN sed -i 's/jdk.tls.disabledAlgorithms=/jdk.tls.disabledAlgorithms=SSLv2Hello, DES40_CBC, RC4_40, SSLv2, TLSv1, TLSv1.1, /g' /etc/java/java-17-openjdk/java-17-openjdk-17.0.3.0.7-2.el8_6.x86_64/conf/security/java.security
USER 1001

# Copy over app from builder image into the runtime image.
RUN mkdir /opt/app
COPY --from=builder /app/target/javaspringapp-1.0-SNAPSHOT.jar /opt/app/app.jar

ENV PORT 8080

EXPOSE 8080

ENTRYPOINT [ "sh", "-c", "java -jar /opt/app/app.jar" ]
