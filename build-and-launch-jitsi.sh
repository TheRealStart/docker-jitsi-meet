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
    echo "${BLUE}Creating config folders if not exist...${NC}"
    if ! sudo mkdir -p ${CONFIG}/{web/letsencrypt,transcripts,prosody/config,prosody/prosody-plugins-custom,jicofo,jvb,jigasi,jibri}; then
        echo "{RED}Failed to create config folders!${NC}"
        sleep 5
        exit 1
    fi

    # Copy prosody custom prosody plugings 
    echo "${BLUE}Copying mod_token_moderation.lua plugin into corresponding config folder...${NC}"
    if ! sudo cp -r ./custom/prosody-plugins-custom/mod_token_moderation.lua ${CONFIG}/prosody/prosody-plugins-custom/; then
        echo "{RED}Failed to copy the plugin!${NC}"
        sleep 5
        exit 1
    fi

    echo "${BLUE}Building custom jitsi/web...${NC}"
    cd web
    echo "${BLUE}Getting latest custom jitsi-meet...${NC}"
    if [ ! -d "trs-jitsi-meet" ]; then
        if ! mkdir trs-jitsi-meet; then
            echo "{RED}Failed to mkdir!${NC}"
            sleep 5
            exit 1
        fi
    fi
    cd trs-jitsi-meet

    # Pull/clone the latest changes from git repo
    if [ ! -d .git ]; then
        if ! git clone github-trs-jitsi-meet:TheRealStart/jitsi-meet.git .; then
            echo "{RED}Failed to git clone!${NC}"
            sleep 5
            exit 1
        fi
        if ! git checkout "$CUSTOM_TRS_JITSI_MEET_BRANCH"; then
            echo "{RED}Failed to git checkout!${NC}"
            sleep 5
            exit 1
        fi
    else
        if ! git fetch; then
            echo "{RED}Failed to git fetch!${NC}"
            sleep 5
            exit 1
        fi
        if ! git checkout "$CUSTOM_TRS_JITSI_MEET_BRANCH"; then
            echo "{RED}Failed to git checkout!${NC}"
            sleep 5
            exit 1
        fi
        if ! git pull; then
            echo "{RED}Failed to git pull!${NC}"
            sleep 5
            exit 1
        fi
    fi

    # Install npm packages
    echo "${BLUE}Installing npm packages...${NC}"
    if ! npm install; then
        echo "{RED}Failed to npm install!${NC}"
        sleep 5
        exit 1
    fi

    # Customize static files
    echo "${BLUE}Customizing static files...${NC}"
    if ! rm -rf images/ title.html favicon.ico; then
        echo "{RED}Failed to remove!${NC}"
        sleep 5
        exit 1
    fi
    cd ..
    if ! cp -r rootfs/defaults/custom/images/ trs-jitsi-meet/; then
        echo "{RED}Failed to copy custom images!${NC}"
        sleep 5
        exit 1
    fi
    if ! cp -r rootfs/defaults/custom/title.html trs-jitsi-meet/; then
        echo "{RED}Failed to copy title.html!${NC}"
        sleep 5
        exit 1
    fi
        if ! cp -r rootfs/defaults/custom/images/favicon.ico trs-jitsi-meet/; then
        echo "{RED}Failed to copy favicon.ico!${NC}"
        sleep 5
        exit 1
    fi

    cd trs-jitis-meet

    # Compile with make and create source package
    echo "${BLUE}Running make command...${NC}"
    if ! make; then
        echo "{RED}Failed to make!${NC}"
        sleep 5
        exit 1
    fi
    if ! make source-package; then
        echo "{RED}Failed to make source-package!${NC}"
        sleep 5
        exit 1
    fi

    # Unpack and build jitsi-meet
    echo "${BLUE}Unpacking and building jitsi-meet...${NC}"
    if ! tar -xzvf trs-jitsi-meet/jitsi-meet.tar.bz2; then
        echo "{RED}Failed to untar!${NC}"
        sleep 5
        exit 1
    fi
    if ! docker build --tag jitsi/web:custom .; then
        echo "{RED}Failed to build docker image!${NC}"
        sleep 5
        exit 1
    fi

    # Launching jitsi services
    cd ..
    docker-compose -f docker-compose-custom.yml up -d --force-recreate
else
    echo "${RED}.env file not found${NC}"
    sleep 5
    exit 1
fi

