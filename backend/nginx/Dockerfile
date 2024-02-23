FROM nginx:stable-alpine

RUN apk add openssl

RUN mkdir /etc/nginx/ssl && openssl req -nodes -x509 -newkey rsa:4096 -keyout /etc/nginx/ssl/pong.key \
-out /etc/nginx/ssl/pong.crt -days 365 -subj "/C=AU/ST=SA/L=Adelaide/O=42"

EXPOSE 80

COPY entrypoint.sh /

RUN chmod +x /entrypoint.sh

#ENTRYPOINT ["sh", "entrypoint.sh"]
