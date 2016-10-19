FROM openjdk:8-jdk-alpine

RUN apk add --no-cache git openssh-client curl zip unzip bash ttf-dejavu coreutils

ENV JENKINS_HOME /var/jenkins_home
ENV JENKINS_SLAVE_AGENT_PORT 50000

ARG VERSION=2.62
ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000

# Jenkins is run with user `jenkins`, uid = 1000
# If you bind mount a volume from the host or a data container, 
# ensure you use the same uid
RUN addgroup -g ${gid} ${group} \
    && adduser -h "$JENKINS_HOME" -u ${uid} -G ${group} -s /bin/bash -D ${user}

ENV COPY_REFERENCE_FILE_LOG $JENKINS_HOME/copy_reference_file.log

RUN apk add --no-cache python \
  python-dev \
  py-openssl \
  openssl \
  openssl-dev \
  py-pip \
  gcc \
  musl-dev \
  libxml2 \
  libxml2-dev \
  libxslt-dev \
  libffi-dev

RUN pip install --upgrade pip \
  && pip install --upgrade Scrapy

# install gcloud sdk
RUN curl https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-130.0.0-linux-x86_64.tar.gz -o /tmp/google-cloud-sdk.tar.gz \
  && tar -zxvf /tmp/google-cloud-sdk.tar.gz \
  && /google-cloud-sdk/install.sh -q 

ADD ./accounts.json /root/.gcp/accounts.json

RUN cat /root/.gcp/accounts.json

RUN CLOUDSDK_PYTHON_SITEPACKAGES=1 /google-cloud-sdk/bin/gcloud auth activate-service-account "jenkins@JENKINS_SVC_ACCOUNT" --key-file /root/.gcp/accounts.json


RUN curl --create-dirs -sSLo /usr/share/jenkins/slave.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${VERSION}/remoting-${VERSION}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/slave.jar


USER jenkins
RUN mkdir /home/jenkins/.jenkins
VOLUME /home/jenkins/.jenkins
WORKDIR /home/jenkins