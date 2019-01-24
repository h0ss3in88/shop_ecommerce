FROM postgres:9.6.1-alpine
ENV POSTGRES_DB balloonshop
ENV POSTGRES_USER hussein
ENV POSTGRES_PASSWORD 123456
ENV ALLOW_IP_RANGE=0.0.0.0/0
EXPOSE 5432
COPY ./balloonshop.sql /docker-entrypoint-initdb.d

