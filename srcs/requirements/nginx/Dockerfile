FROM debian:bullseye

RUN apt update -y && apt upgrade -y && apt install -y \
		nginx \
		openssl \
		gettext-base

COPY nginx.conf /etc/nginx/sites-available/default
COPY script.sh .
RUN chmod +x script.sh

CMD ["./script.sh"]
