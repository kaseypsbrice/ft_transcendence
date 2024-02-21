FROM debian:bookworm

ENV BUNDLE_SILENCE_ROOT_WARNING=true

RUN apt-get update && apt-get -y upgrade
RUN apt-get install -y ruby-full ruby-bundler make gcc g++ libpq-dev
RUN mkdir /var/server

COPY srcs/Gemfile /var/server/Gemfile

RUN cd /var/server && bundle

EXPOSE 8080

COPY entrypoint.sh /

ENTRYPOINT ["/bin/sh", "entrypoint.sh"]