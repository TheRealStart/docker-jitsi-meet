ARG VERSION=stable-5142-3

FROM jitsi/prosody:${VERSION}

ENV XMPP_CROSS_DOMAIN="false"

RUN patch -d /usr/lib/prosody/modules/muc -p0 < /prosody-plugins/muc_owner_allow_kick.patch

COPY rootfs/ /

COPY --from=builder /usr/local/lib/lua /usr/local/lib/lua
COPY --from=builder /usr/local/share/lua /usr/local/share/lua

EXPOSE 5222 5347 5280

VOLUME ["/config", "/prosody-plugins-custom"]
