FROM debian:bullseye

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y vsftpd && \
    rm -rf /var/lib/apt/lists/*

COPY vsftpd.conf /etc/vsftpd.conf
COPY script.sh /usr/local/bin/script.sh

RUN chmod +x /usr/local/bin/script.sh

EXPOSE 21 40000 40001 40002 40003 40004 40005

CMD ["/usr/local/bin/script.sh"]
