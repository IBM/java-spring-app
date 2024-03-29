# WARNING: This repository is no longer maintained :warning:

> This repository will not be updated. The repository will be kept available in read-only mode.
<p align="center">
    <a href="https://cloud.ibm.com">
        <img src="https://cloud.ibm.com/media/docs/developer-appservice/resources/ibm-cloud.svg" height="100" alt="IBM Cloud">
    </a>
</p>


<p align="center">
    <a href="https://cloud.ibm.com">
    <img src="https://img.shields.io/badge/IBM%20Cloud-powered-blue.svg" alt="IBM Cloud">
    </a>
    <a href="https://www.ibm.com/developerworks/learn/java/">
    <img src="https://img.shields.io/badge/platform-java-lightgrey.svg?style=flat" alt="platform">
    </a>
    <img src="https://img.shields.io/badge/license-Apache2-blue.svg?style=flat" alt="Apache 2">
</p>


# Create and deploy a basic Java Spring application

> We have applications available for [Node.js Express](https://github.com/IBM/node-express-app), [Go Gin](https://github.com/IBM/go-gin-app), [Python Flask](https://github.com/IBM/python-flask-app), [Python Django](https://github.com/IBM/python-django-app), [Java Spring](https://github.com/IBM/java-spring-app), [Java Liberty](https://github.com/IBM/java-liberty-app), [Swift Kitura](https://github.com/IBM/swift-kitura-app), [Android](https://github.com/IBM/android-app), and [iOS](https://github.com/IBM/ios-app).

In this sample application, you will create a basic Java cloud application using Spring. This provides a good starting point for creating Java microservice applications running on [Spring](https://spring.io/). It contains no default application code, but comes with standard best practices, including a health check.

Capabilities are provided through dependencies in the `pom.xml` file. The ports are set to the defaults of `8080` for http and `8443` for https and are exposed to the CLI in the `cli-config.yml` file. The ports are set in the `pom.xml` file and exposed to the CLI in the `cli-config.yml` file.

The application exposes the following endpoints:
* Health endpoint: `<host>:<port>/health` e.g. http://localhost:8080/health
* Web content: `<host>:<port>`

## Steps

### Deploying to IBM Cloud

[IBM Cloud DevOps](https://www.ibm.com/cloud/devops) services provides toolchains as a set of tool integrations that support development, deployment, and operations tasks inside IBM Cloud.

### Building Locally

To get started building this application locally, you can either run the application natively or use the [IBM Cloud Developer Tools](https://cloud.ibm.com/docs/cli?topic=cloud-cli-getting-started) for containerization and easy deployment to IBM Cloud.

#### Native Application Development

* [Maven](https://maven.apache.org/install.html)
* Java 8: Any compliant JVM should work.
  * [Java 8 JDK from Oracle](http://www.oracle.com/technetwork/java/javase/downloads/index.html)
  * [Java 8 JDK from IBM (AIX, Linux, z/OS, IBM i)](http://www.ibm.com/developerworks/java/jdk/),
    or [Download a Liberty server package](https://developer.ibm.com/assets/wasdev/#filter/assetTypeFilters=PRODUCT)
    that contains the IBM JDK (Windows, Linux)

To build and run an application:

1. `mvn install`
2. `java -jar ./target/javaspringapp-1.0-SNAPSHOT.jar`

To run an application in Docker use the Docker file called `Dockerfile`. If you do not want to install Maven locally you can use `Dockerfile-tools` to build a container with Maven installed.

You can verify the state of your locally running application using the Selenium UI test script included in the `scripts` directory.

#### IBM Cloud Developer Tools

Install [IBM Cloud Developer Tools](https://cloud.ibm.com/docs/cli?topic=cloud-cli-getting-started) on your machine by running the following command:
```
curl -sL https://ibm.biz/idt-installer | bash
```

Create an application on IBM Cloud by running:

```bash
ibmcloud dev create
```

This will create and download a starter application with the necessary files needed for local development and deployment.

Your application will be compiled with Docker containers. To compile and run your app, run:

```bash
ibmcloud dev build
ibmcloud dev run
```

This will launch your application locally. When you are ready to deploy to IBM Cloud on Kubernetes, run one of the following commands:

```bash
ibmcloud dev deploy -t container // to K8s cluster
```

You can build and debug your app locally with:

```bash
ibmcloud dev build --debug
ibmcloud dev debug
```

## CRA Scanning 

This repository includes a `.cracveomit` file that is used by Code Risk Analyzer (CRA) in IBM Cloud Continuous Delivery. This file helps address vulnerabilities that are found by CRA until a remediation is available, at which point the vulnerabilities will be addressed in the respective package versions. CRA keeps the code in this repository free of known vulnerabilities, and therefore helps make applications that are built on this code more secure. If you are not using CRA, you can safely ignore this file.

## License

This sample application is licensed under the Apache License, Version 2. Separate third-party code objects invoked within this code pattern are licensed by their respective providers pursuant to their own separate licenses. Contributions are subject to the [Developer Certificate of Origin, Version 1.1](https://developercertificate.org/) and the [Apache License, Version 2](https://www.apache.org/licenses/LICENSE-2.0.txt).

[Apache License FAQ](https://www.apache.org/foundation/license-faq.html#WhatDoesItMEAN)
