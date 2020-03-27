ARG JITSI_REPO=jitsi
FROM ${JITSI_REPO}/base

ADD https://raw.githubusercontent.com/acmesh-official/acme.sh/2.8.8/acme.sh /opt
COPY rootfs/ /

RUN \
	apt-dpkg-wrap apt-get update && \
	apt-dpkg-wrap apt-get install -y cron nginx-extras jitsi-meet-web socat && \
	apt-dpkg-wrap apt-get -d install -y jitsi-meet-web-config && \
    dpkg -x /var/cache/apt/archives/jitsi-meet-web-config*.deb /tmp/pkg && \
    mv /tmp/pkg/usr/share/jitsi-meet-web-config/config.js /defaults && \
	mv /usr/share/jitsi-meet/interface_config.js /defaults && \
	rm -f /etc/nginx/conf.d/default.conf && \
	apt-cleanup && \
	rm -rf /tmp/pkg /var/cache/apt
	# Customizations
	rm -f /usr/share/jitsi-meet/title.html && \
	rm -f /usr/share/jitsi-meet/favicon.ico && \
	rm -f /usr/share/jitsi-meet/images/favicon.ico && \
	rm -f /usr/share/jitsi-meet/images/watermark.png && \
	rm -f /usr/share/jitsi-meet/images/logo-deep-linking.png &&

EXPOSE 80 443

VOLUME ["/config", "/usr/share/jitsi-meet/transcripts"]
