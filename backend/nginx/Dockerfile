FROM nginx:stable-alpine

RUN apk add openssl

RUN mkdir /etc/nginx/ssl

EXPOSE 80

COPY entrypoint.sh /

RUN chmod +x /entrypoint.sh

#ENTRYPOINT ["sh", "entrypoint.sh"]
