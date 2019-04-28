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

FROM debian:stable-slim

RUN apt-get update
RUN apt-get install -y openssl libyaml-0-2 ca-certificates

COPY --from=build_env /usr/local/lib/libgetdns.so.10 /usr/local/lib
COPY --from=build_env /usr/local/bin/stubby /usr/local/bin
COPY --from=build_env /usr/local/etc/stubby/stubby.yml /usr/local/etc/stubby/

RUN ldconfig

CMD ["/usr/local/bin/stubby"]
