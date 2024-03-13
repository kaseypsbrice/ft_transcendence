FROM postgres:16.2-bookworm

RUN chmod -R a+rwx /var/lib/postgresql
COPY ./init-db.sh /docker-entrypoint-initdb.d/
RUN chmod +x /docker-entrypoint-initdb.d/

USER postgres
#ENTRYPOINT ["bash", "init-db.sh"]

#CMD ["postgres"]