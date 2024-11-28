FROM debian:bullseye

RUN apt update -y && apt upgrade -y && apt install -y nginx openssl

COPY conf/nginx.conf /etc/nginx/sites-available/default
COPY script.sh .
RUN chmod +x script.sh

CMD ["./script.sh"]
