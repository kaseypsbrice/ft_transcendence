FROM debian:bookworm

ENV BUNDLE_SILENCE_ROOT_WARNING=true

SHELL ["/bin/bash", "-l", "-c"]
RUN apt-get update && apt-get -y upgrade
RUN apt-get install -y make gcc g++ libpq-dev openssl gnupg2 curl procps; \
gpg2 --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB; \
\curl -sSL https://get.rvm.io | bash -s stable; usermod -aG rvm root
RUN rvm install 3.2.0

COPY srcs/Gemfile /var/server/Gemfile

RUN cd /var/server && bundle


COPY entrypoint.sh /
RUN chmod +x entrypoint.sh

ENTRYPOINT ["/bin/bash", "-l", "-c", "./entrypoint.sh"]