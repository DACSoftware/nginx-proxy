FROM nginx:1.11.3
MAINTAINER Jason Wilder mail@jasonwilder.com

# Install wget and install/updates certificates
RUN apt-get update \
 && apt-get install -y -q --no-install-recommends \
    ca-certificates \
    wget \
 && apt-get clean \
 && rm -r /var/lib/apt/lists/*

# Configure Nginx and apply fix for very long server names
RUN echo "daemon off;" >> /etc/nginx/nginx.conf \
 && sed -i 's/^http {/&\n    server_names_hash_bucket_size 128;/g' /etc/nginx/nginx.conf

# Install Forego
ADD https://github.com/jwilder/forego/releases/download/v0.16.1/forego /usr/local/bin/forego
RUN chmod u+x /usr/local/bin/forego

ENV DOCKER_GEN_VERSION 0.7.3

RUN wget https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz \
 && tar -C /usr/local/bin -xvzf docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz \
 && rm /docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz

COPY phpdeployer.id_rsa /root/.ssh/id_rsa

RUN git clone git@bitbucket.org:dacsoftware/certificates.git /opt/certificates
RUN rm -r /root/.ssh/id_rsa

COPY . /app/
WORKDIR /app/

RUN cat \
  tmpl/upstream.tmpl \
  tmpl/default_503.tmpl \
  tmpl/proxy_headers.tmpl \
  tmpl/service/*.tmpl \
  tmpl/host.tmpl \
  tmpl/hosts.tmpl \
  tmpl/main.tmpl \
  > nginx.tmpl

RUN cat \
  tmpl/certs/issue-cert.tmpl \
  tmpl/certs/gen-certs.tmpl \
  > certs.tmpl

ENV DOCKER_HOST unix:///tmp/docker.sock

VOLUME ["/etc/nginx/certs"]

ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["forego", "start", "-r"]
