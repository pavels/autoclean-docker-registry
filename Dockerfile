FROM ruby:2.5-alpine3.7

RUN set -ex \
    && apk add --no-cache ca-certificates apache2-utils supervisor
RUN bundle config --global frozen 1

COPY ./distribution-library-image/amd64/registry /bin/registry
COPY ./distribution-library-image/amd64/config-example.yml /etc/docker/registry/config.yml
COPY ./run_registry.sh /run_registry.sh
RUN chmod +x /run_registry.sh

ADD cleaner /cleaner
WORKDIR cleaner
RUN bundle install
RUN chmod +x cron.rb
WORKDIR /

COPY ./supervisord.conf /etc/supervisord.conf

VOLUME ["/var/lib/registry"]
EXPOSE 5000

ENTRYPOINT ["supervisord", "--nodaemon", "--configuration", "/etc/supervisord.conf"]
