ARG VERSION=stable-5142-3

FROM jitsi/prosody:${VERSION}

COPY rootfs/ /

EXPOSE 5222 5347 5280

VOLUME ["/config", "/prosody-plugins-custom"]
