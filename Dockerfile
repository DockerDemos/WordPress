# Docker container for a WordPress website
# http://wordpress.org
#
# Build from lastest stable source code


FROM centos:centos6
MAINTAINER Chris Collins <collins.christopher@gmail.com>

ADD . /build
RUN /build/pre-install.sh 
RUN /build/config.sh
RUN /build/post-install.sh

EXPOSE 80 
EXPOSE 443 

CMD ["/bin/bash", "/build/startup.sh"]
