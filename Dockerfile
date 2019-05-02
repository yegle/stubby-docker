FROM debian:stable as build_env

RUN apt-get update
RUN apt-get install -y \
    build-essential git libtool-bin automake libssl-dev libyaml-dev

RUN git clone https://github.com/getdnsapi/getdns.git
WORKDIR /getdns
RUN git submodule update --init
RUN libtoolize -ci
RUN autoreconf -fi
RUN ./configure --enable-stub-only --without-libidn --without-libidn2
RUN make && make install

WORKDIR /getdns/stubby
RUN autoreconf -vfi && ./configure && make && make install

RUN strip -s /usr/local/lib/libgetdns.so.10 \
    /usr/local/bin/stubby \
    /usr/local/bin/getdns_server_mon

FROM gcr.io/distroless/base

COPY --from=build_env /usr/local/lib/libgetdns.so.10 /lib/x86_64-linux-gnu/
COPY --from=build_env /usr/local/bin/stubby /bin/
COPY --from=build_env /usr/local/bin/getdns_server_mon /bin/
COPY --from=build_env /usr/local/etc/stubby/stubby.yml /usr/local/etc/stubby/
COPY --from=build_env /usr/lib/x86_64-linux-gnu/libyaml-0.so.2 /lib/x86_64-linux-gnu/

HEALTHCHECK CMD ["/bin/getdns_server_mon", "-M", "-t", "@127.0.0.1", "lookup", "google.com"]

ENTRYPOINT ["/bin/stubby"]
