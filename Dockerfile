FROM debian:buster as build_env
ARG SOURCE_BRANCH
ENV GETDNS_VERSION=${SOURCE_BRANCH:-1.5.2}

ENV STUBBY_URL https://getdnsapi.net/dist/getdns-${GETDNS_VERSION}.tar.gz

RUN apt-get update
RUN apt-get install -y build-essential curl libexpat-dev libtool-bin automake \
        libyaml-dev libssl-dev

WORKDIR /tmp/build
RUN curl -v -O ${STUBBY_URL}
RUN tar xvf getdns-${GETDNS_VERSION}.tar.gz
WORKDIR /tmp/build/getdns-${GETDNS_VERSION}
RUN ./configure --enable-stub-only --without-libidn --without-libidn2 \
        --with-stubby
RUN make && make install

RUN strip -s /usr/local/bin/getdns_server_mon
RUN strip -s /usr/local/bin/stubby
RUN strip -s /usr/local/lib/libgetdns.so.10
RUN setcap 'cap_net_bind_service=+ep' /usr/local/bin/stubby

FROM gcr.io/distroless/base-debian10:nonroot

COPY --from=build_env /usr/local/lib/libgetdns.so.10 /lib/x86_64-linux-gnu/
COPY --from=build_env /usr/local/bin/stubby /bin/
COPY --from=build_env /usr/local/bin/getdns_server_mon /bin/
COPY --from=build_env /usr/lib/x86_64-linux-gnu/libyaml-0.so.2 /lib/x86_64-linux-gnu/

HEALTHCHECK CMD ["/bin/getdns_server_mon", "-M", "-t", "@127.0.0.1", "lookup", "google.com"]

ENTRYPOINT ["/bin/stubby"]
