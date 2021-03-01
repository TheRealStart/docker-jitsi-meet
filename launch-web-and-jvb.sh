#!/bin/bash

RED='\033[0;31m' # for errors
GREEN='\033[0;32m' # for commands
BLUE='\033[0;34m' # for infos
YELLOW='\033[1;33m' # for warnings
NC='\033[0m' # no color

envFile=".env"

if [[ -f $envFile ]]; then
    # Load environment variables
    set -a
    source ${envFile}

    # Launching jitsi services
    docker-compose -f web-and-jvb-custom.yml up -d --force-recreate

     # Customize interface config
    echo -e "${BLUE}Customizing interface config...${NC}"
    if ! sudo sed -i \
        -e "s#DEFAULT_REMOTE_DISPLAY_NAME:.*#DEFAULT_REMOTE_DISPLAY_NAME: 'Participant',#" \
        -e "s#APP_NAME:.*#APP_NAME: '$APP_NAME',#" \
        -e "s#NATIVE_APP_NAME:.*#NATIVE_APP_NAME: '$APP_NAME',#" \
        -e "s#PROVIDER_NAME:.*#PROVIDER_NAME: '$APP_NAME',#" \
        -e "s#JITSI_WATERMARK_LINK:.*#JITSI_WATERMARK_LINK: '$WATERMARK_URL',#" \
        -e "s#DISABLE_VIDEO_BACKGROUND:.*#DISABLE_VIDEO_BACKGROUND: true,#" \
        -e "s#DISABLE_DOMINANT_SPEAKER_INDICATOR:.*#DISABLE_DOMINANT_SPEAKER_INDICATOR: true,#" \
        -e "s#DISABLE_JOIN_LEAVE_NOTIFICATIONS:.*#DISABLE_JOIN_LEAVE_NOTIFICATIONS: true,#" \
        -e "s#// MOBILE_DOWNLOAD_LINK_ANDROID:.*#MOBILE_DOWNLOAD_LINK_ANDROID: '$MOBILE_DOWNLOAD_LINK_ANDROID',#" \
        -e "s#// MOBILE_DOWNLOAD_LINK_IOS:.*#MOBILE_DOWNLOAD_LINK_IOS: '$MOBILE_DOWNLOAD_LINK_IOS',#" \
        -e "s#DISABLE_JOIN_LEAVE_NOTIFICATIONS:.*#DISABLE_JOIN_LEAVE_NOTIFICATIONS: false,#" \
        -e "s#'info', ##" \
        -e "s#'sharedvideo', ##" \
        -e "s#'download', ##" \
        -e "s#'help', ##" \
        ${CONFIG}/web/interface_config.js; then
            echo -e "${RED}Failed to customize interface_config.js!${NC}"
            sleep 5
            exit 1
    fi
else
    echo -e "${RED}.env file not found${NC}"
    sleep 5
    exit 1
fi

