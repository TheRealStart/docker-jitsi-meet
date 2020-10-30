ARG JITSI_REPO=jitsi
FROM ${JITSI_REPO}/base-java

RUN \
	apt-dpkg-wrap apt-get update && \
	apt-dpkg-wrap apt-get install -y jitsi-videobridge2 jq curl iproute2 && \
	apt-cleanup

COPY rootfs/ /
COPY trs-jvb/jitsi-videobridge-2.1-SNAPSHOT/ /usr/share/jitsi-videobridge/

VOLUME /config
