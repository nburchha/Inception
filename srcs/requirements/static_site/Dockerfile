FROM alpine:3.19

RUN apk update && apk add --no-cache nodejs

WORKDIR /var/www/static_site

COPY conf/server.js .
COPY tools/index.html .
COPY tools/style.css .
COPY tools/script.js .

EXPOSE 3000

CMD ["node", "server.js"]