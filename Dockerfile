FROM alpine:3.7

RUN apk update && apk add --update --no-cache rethinkdb

VOLUME /data
WORKDIR /data

EXPOSE 28015 29015 8080
ENTRYPOINT ["rethinkdb"]
CMD ["--bind", "all"]

ARG DUMB_INIT_VERSION=1.2.0

RUN apk add --update --no-cache dumb-init

COPY ./start-rethinkdb.sh /

ENTRYPOINT ["dumb-init", "/start-rethinkdb.sh"]
