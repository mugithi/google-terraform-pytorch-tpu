FROM google/cloud-sdk
MAINTAINER Vic Iglesias <viglesias@google.com>

RUN apt-get install nmap -y 
COPY run-builder.sh /bin
CMD ["bash", "-xe", "/bin/run-builder.sh"]

