ARG VERSION=stable-5142-3

FROM jitsi/web:${VERSION}

COPY rootfs/defaults/settings-config.js /defaults/settings-config.js
COPY rootfs/defaults/system-config.js /defaults/system-config.js
COPY rootfs/defaults/meet.conf /defaults/meet.conf
COPY rootfs/defaults/meet.conf /config/nginx/meet.conf

COPY jitsi-meet/ /usr/share/jitsi-meet/

EXPOSE 80 443

VOLUME ["/config", "/usr/share/jitsi-meet/transcripts"]
