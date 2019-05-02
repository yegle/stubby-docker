# stubby-docker

Quick start:

```
curl -O stubby.yml \
    https://raw.githubusercontent.com/getdnsapi/stubby/develop/stubby.yml.example
stubby run \
    -v $(PWD)/stubby.yml:/usr/local/etc/stubby/stubby.yml:ro \
    yegle/stubby-dns:latest
```
