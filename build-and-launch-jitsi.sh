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

    # Config folders
    echo -e "${BLUE}Creating config folders if not exist...${NC}"
    if ! sudo mkdir -p ${CONFIG}/{web/letsencrypt,transcripts,prosody/config,prosody/prosody-plugins-custom,jicofo,jvb,jigasi,jibri}; then
        echo -e "${RED}Failed to create config folders!${NC}"
        sleep 5
        exit 1
    fi

    # Copy prosody custom prosody plugings 
    echo -e "${BLUE}Copying mod_token_moderation.lua plugin into corresponding config folder...${NC}"
    if ! sudo cp -r ./custom/prosody-plugins-custom/mod_token_moderation.lua ${CONFIG}/prosody/prosody-plugins-custom/; then
        echo -e "${RED}Failed to copy the plugin!${NC}"
        sleep 5
        exit 1
    fi

    # Build jitsi/web:custom
    echo -e "${BLUE}Building custom jitsi/web...${NC}"
    cd web
    echo -e "${BLUE}Getting latest custom jitsi-meet...${NC}"
    if [ ! -d "trs-jitsi-meet" ]; then
        if ! mkdir -p trs-jitsi-meet; then
            echo -e "${RED}Failed to mkdir!${NC}"
            sleep 5
            exit 1
        fi
    fi
    cd trs-jitsi-meet

    # Pull/clone the latest changes from git repo
    if [ ! -d .git ]; then
        rm -rf *
        if ! git clone github-trs-jitsi-meet:TheRealStart/jitsi-meet.git .; then
            echo -e "${RED}Failed to git clone!${NC}"
            sleep 5
            exit 1
        fi
        if ! git checkout "$CUSTOM_TRS_JITSI_MEET_BRANCH"; then
            echo -e "${RED}Failed to git checkout!${NC}"
            sleep 5
            exit 1
        fi
    else
        if ! git fetch; then 
            echo -e "${RED}Failed to git fetch${NC}"
            sleep 5
            exit 1
        fi
        if ! git add .; then
            echo -e "${RED}Failed to git add${NC}"
            sleep 5
            exit 1
        fi
        git commit -m "commiting changes if needed"
        if ! git checkout "$CUSTOM_TRS_JITSI_MEET_BRANCH"; then
            echo -e "${RED}Failed to git checkout${NC}"
            sleep 5
            exit 1
        fi
        if ! git pull; then
            echo -e "${RED}Failed to git pull${NC}"
            sleep 5
            exit 1
        fi
    fi

    rm -rf package-lock.json
    rm -rf node_modules/

    # Install npm packages
    echo -e "${BLUE}Installing npm packages...${NC}"
    if ! npm install; then
        echo -e "${RED}Failed to npm install!${NC}"
        sleep 5
        exit 1
    fi

    # Customize static files
    echo -e "${BLUE}Customizing static files...${NC}"
    if ! rm -rf images/ title.html favicon.ico; then
        echo -e "${RED}Failed to remove!${NC}"
        sleep 5
        exit 1
    fi
    cd ..
    if ! cp -r rootfs/defaults/custom/images/ trs-jitsi-meet/; then
        echo -e "${RED}Failed to copy custom images!${NC}"
        sleep 5
        exit 1
    fi
    if ! cp -r rootfs/defaults/custom/title.html trs-jitsi-meet/; then
        echo -e "${RED}Failed to copy title.html!${NC}"
        sleep 5
        exit 1
    fi
        if ! cp -r rootfs/defaults/custom/images/favicon.ico trs-jitsi-meet/; then
        echo -e "${RED}Failed to copy favicon.ico!${NC}"
        sleep 5
        exit 1
    fi

    cd trs-jitsi-meet

    # Compile with make and create source package
    echo -e "${BLUE}Running make command...${NC}"
    if ! make; then
        echo -e "${RED}Failed to make!${NC}"
        sleep 5
        exit 1
    fi
    if ! make source-package; then
        echo -e "${RED}Failed to make source-package!${NC}"
        sleep 5
        exit 1
    fi

    # Unpack and build jitsi-meet
    echo -e "${BLUE}Unpacking and building jitsi-meet...${NC}"
    cd ..
    if ! tar xf trs-jitsi-meet/jitsi-meet.tar.bz2; then
        echo -e "${RED}Failed to untar!${NC}"
        sleep 5
        exit 1
    fi
    if ! docker build --tag jitsi/web:custom .; then
        echo -e "${RED}Failed to build docker image!${NC}"
        sleep 5
        exit 1
    fi

    cd ..

    # Build jvb:custom
    cd jvb
    echo -e "${BLUE}Getting latest custom jvb codebase...${NC}"
    if [ ! -d "trs-jvb" ]; then
        mkdir trs-jvb
    fi
    cd trs-jvb
    if [ ! -d .git ]; then 
        if ! git clone github-trs-jvb:TheRealStart/jitsi-videobridge.git .; then
            echo -e "${RED}Failed to clone jvb!${NC}"
            sleep 5
            exit 1
        fi
        if ! git add .; then
            echo -e "${RED}Failed to git add${NC}"
            sleep 5
            exit 1
        fi
        git commit -m "commiting changes if needed"
        if ! git checkout "$CUSTOM_TRS_JVB_BRANCH"; then
            echo -e "${RED}Failed to git checkout${NC}"
            sleep 5
            exit 1
        fi
    else
        if ! git fetch; then 
            echo -e "${RED}Failed to git fetch${NC}"
            sleep 5
            exit 1
        fi
        if ! git add .; then
            echo -e "${RED}Failed to git add${NC}"
            sleep 5
            exit 1
        fi
        git commit -m "commiting changes if needed"
        if ! git checkout "$CUSTOM_TRS_JVB_BRANCH"; then
            echo -e "${RED}Failed to git checkout${NC}"
            sleep 5
            exit 1
        fi
        if ! git pull; then
            echo -e "${RED}Failed to git pull${NC}"
            sleep 5
            exit 1
        fi
    fi
    if ! mvn package -DskipTests -Dassembly.skipAssembly=false; then
        echo -e "${RED}Failed to mvn package${NC}"
        sleep 5
        exit 1
    fi
    if ! unzip -o jvb/target/jitsi-videobridge-2.1-SNAPSHOT-archive.zip; then
        echo -e "${RED}Failed to unzip ${NC}"
        sleep 5
        exit 1
    fi
    cd ..
    
    echo "${BLUE}Building custom jvb...${NC}"
        if ! docker build --tag jitsi/jvb:custom .; then
            echo -e "${RED}Failed to docker build${NC}"
            sleep 5
            exit 1
        fi
    cd ..

    # Launching jitsi services
    docker-compose -f docker-compose-custom.yml up -d --force-recreate

     # Customize interface config
    echo -e "${BLUE}Customizing interface config...${NC}"
    if ! sudo sed -i \
        -e "s#DEFAULT_REMOTE_DISPLAY_NAME:.*#DEFAULT_REMOTE_DISPLAY_NAME: 'Participant',#" \
        -e "s#APP_NAME:.*#APP_NAME: '$CUSTOM_APP_NAME',#" \
        -e "s#NATIVE_APP_NAME:.*#NATIVE_APP_NAME: '$CUSTOM_APP_NAME',#" \
        -e "s#PROVIDER_NAME:.*#PROVIDER_NAME: '$CUSTOM_APP_NAME',#" \
        -e "s#JITSI_WATERMARK_LINK:.*#JITSI_WATERMARK_LINK: '$CUSTOM_WATERMARK_URL',#" \
        -e "s#DISABLE_VIDEO_BACKGROUND:.*#DISABLE_VIDEO_BACKGROUND: true,#" \
        -e "s#DISABLE_DOMINANT_SPEAKER_INDICATOR:.*#DISABLE_DOMINANT_SPEAKER_INDICATOR: true,#" \
        -e "s#DISABLE_JOIN_LEAVE_NOTIFICATIONS:.*#DISABLE_JOIN_LEAVE_NOTIFICATIONS: true,#" \
        -e "s#// MOBILE_DOWNLOAD_LINK_ANDROID:.*#MOBILE_DOWNLOAD_LINK_ANDROID: '$MOBILE_DOWNLOAD_LINK_ANDROID',#" \
        -e "s#// MOBILE_DOWNLOAD_LINK_IOS:.*#MOBILE_DOWNLOAD_LINK_IOS: '$MOBILE_DOWNLOAD_LINK_IOS',#" \
        -e "s#'info', ##" \
        -e "s#'sharedvideo', ##" \
        -e "s#'invite', ##" \
        -e "s#'videobackgroundblur', ##" \
        -e "s#'download', ##" \
        -e "s#'help', ##" \
        -e "s#'download', ##" \
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

