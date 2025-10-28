FROM postgres:17.6-alpine

ENV POSTGRES_DB=molha_me_db

ENV POSTGRES_PASSWORD=123456

COPY molha_me_db.sql /docker-entrypoint-initdb.d/

EXPOSE 5432
