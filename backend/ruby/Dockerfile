FROM debian:bookworm

ENV BUNDLE_SILENCE_ROOT_WARNING=true

RUN apt-get update && apt-get -y upgrade
RUN apt-get install -y ruby-full ruby-bundler make gcc g++ libpq-dev openssl
RUN mkdir /var/server /var/ssl && openssl req -nodes -x509 -newkey rsa:4096 -keyout /var/ssl/pong.key \
-out /var/ssl/pong.crt -days 365 -subj "/C=AU/ST=SA/L=Adelaide/O=42"

COPY srcs/Gemfile /var/server/Gemfile

RUN cd /var/server && bundle

EXPOSE 8080

COPY entrypoint.sh /

ENTRYPOINT ["/bin/sh", "entrypoint.sh"]