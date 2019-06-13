FROM debian:stretch as build_env

ENV STUBBY_VERSION 1.5.2
ENV OPENSSL_VERSION 1.1.1c

ENV STUBBY_URL https://getdnsapi.net/dist/getdns-${STUBBY_VERSION}.tar.gz
ENV OPENSSL_URL https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz

RUN apt-get update
RUN apt-get install -y curl build-essential libexpat-dev libtool-bin automake libyaml-dev

WORKDIR /tmp/build
RUN curl -O ${OPENSSL_URL}
RUN tar xvf openssl-${OPENSSL_VERSION}.tar.gz
WORKDIR /tmp/build/openssl-${OPENSSL_VERSION}
RUN ./config
RUN make install_runtime install_dev

WORKDIR /tmp/build
RUN curl -O ${STUBBY_URL}
RUN tar xvf getdns-${STUBBY_VERSION}.tar.gz
WORKDIR /tmp/build/getdns-${STUBBY_VERSION}
RUN ./configure --enable-stub-only --without-libidn --without-libidn2 \
        --with-stubby --with-ssl=/usr/local
RUN make && make install

RUN strip -s /usr/local/lib/libgetdns.so.10
RUN strip -s /usr/local/bin/stubby
RUN strip -s /usr/local/bin/getdns_server_mon
RUN strip -s /usr/local/lib/libcrypto.so.1.1
RUN strip -s /usr/local/lib/libssl.so.1.1

FROM gcr.io/distroless/base

COPY --from=build_env /usr/local/lib/libgetdns.so.10 /lib/x86_64-linux-gnu/
COPY --from=build_env /usr/local/lib/libcrypto.so.1.1 /lib/x86_64-linux-gnu/
COPY --from=build_env /usr/local/lib/libssl.so.1.1 /lib/x86_64-linux-gnu/
COPY --from=build_env /usr/local/bin/stubby /bin/
COPY --from=build_env /usr/local/bin/getdns_server_mon /bin/
COPY --from=build_env /usr/lib/x86_64-linux-gnu/libyaml-0.so.2 /lib/x86_64-linux-gnu/

HEALTHCHECK CMD ["/bin/getdns_server_mon", "-M", "-t", "@127.0.0.1", "lookup", "google.com"]

ENTRYPOINT ["/bin/stubby"]
