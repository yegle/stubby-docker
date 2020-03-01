FROM debian:buster as build_env
ARG SOURCE_BRANCH
ENV GETDNS_VERSION=${SOURCE_BRANCH:-1.6.0}

ENV STUBBY_URL https://getdnsapi.net/dist/getdns-${GETDNS_VERSION}.tar.gz

RUN apt-get update
RUN apt-get install -y build-essential curl libexpat-dev libtool-bin cmake \
        libyaml-dev libssl-dev check

WORKDIR /tmp/build
RUN curl -v -O ${STUBBY_URL}
RUN tar xvf getdns-${GETDNS_VERSION}.tar.gz
WORKDIR /tmp/build/getdns-${GETDNS_VERSION}
RUN cmake -DUSE_LIBIDN2=OFF -DENABLE_STUB_ONLY=ON -DBUILD_STUBBY=ON .
RUN make && make install

RUN strip -s /usr/local/bin/getdns_server_mon
RUN strip -s /usr/local/bin/stubby
RUN strip -s /usr/local/lib/libgetdns.so.10
#RUN setcap 'cap_net_bind_service=+ep' /usr/local/bin/stubby

# Unfortunately copying file from another container during multi-stage build
# won't preserve the extended attributes, thus I can't use the nonroot image,
# and there's no :latest image that I can use.
# Use :debug build for now.
FROM gcr.io/distroless/base-debian10:debug

COPY --from=build_env /usr/local/lib/libgetdns.so.10 /lib/x86_64-linux-gnu/
COPY --from=build_env /usr/local/bin/stubby /bin/
COPY --from=build_env /usr/local/bin/getdns_server_mon /bin/
COPY --from=build_env /usr/lib/x86_64-linux-gnu/libyaml-0.so.2 /lib/x86_64-linux-gnu/

HEALTHCHECK CMD ["/bin/getdns_server_mon", "-M", "-t", "@127.0.0.1", "lookup", "google.com"]

ENTRYPOINT ["/bin/stubby"]
