# IBM Java SDK UBI is not available on public docker yet. Use regular
# base as builder until this is ready. For reference:
# https://github.com/ibmruntimes/ci.docker/tree/master/ibmjava/8/sdk/ubi-min

FROM ibmjava:8-sdk AS builder
LABEL maintainer="IBM Java Engineering at IBM Cloud"

WORKDIR /app
COPY . /app

RUN apt-get update && apt-get install -y maven
RUN mvn -N io.takari:maven:wrapper -Dmaven=3.5.0
RUN ./mvnw install

# Multi-stage build. New build stage that uses the UBI as the base image.

# In the short term, we are using the OpenJDK for UBI. Long term, we will use
# the IBM Java Small Footprint JVM (SFJ) for UBI, but that is not in public
# Docker at the moment.
# (https://github.com/ibmruntimes/ci.docker/tree/master/ibmjava/8/sfj/ubi-min)

FROM adoptopenjdk/openjdk8:ubi-jre

# Copy over app from builder image into the runtime image.
RUN mkdir /opt/app
COPY --from=builder /app/target/javaspringapp-1.0-SNAPSHOT.jar /opt/app/app.jar

ENTRYPOINT [ "sh", "-c", "java -jar /opt/app/app.jar" ]