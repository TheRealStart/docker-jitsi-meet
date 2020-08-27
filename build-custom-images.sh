#!/bin/bash

envFile=".env"

# To be able to run this script, following instruction shall be done.
# 1. To use multiple deploy keys for diff repos we used alias names for github repos.
# https://stackoverflow.com/questions/10041082/how-to-add-deploy-key-for-2-repo-with-1-user-on-github
# 2. Need to install nvm, npm
# 3. Need to install maven
# 4. Need to install zip
# 5. Need to install g++ or build-essentials
# NOTE: webpack -p may cause memory limit exceeded exception, to avoid this use following command:
# export NODE_OPTIONS=--max_old_space_size=4096

if [ -f $envFile ]; then
  set -a
  source $envFile

  CUSTOM_TRS_JITSI_MEET_BRANCH="${CUSTOM_TRS_JITSI_MEET_BRANCH:=stable/jitsi-meet_4548}"
  CUSTOM_TRS_JICOFO_BRANCH="${CUSTOM_TRS_JICOFO_BRANCH:=stable/jitsi-meet_4548}"

  echo "Building custom jitsi/web"
  cd web
  echo "Getting latest custom jitsi-meet codebase"
  if [ ! -d "trs-jitsi-meet" ]; then
    mkdir trs-jitsi-meet
  fi
  cd trs-jitsi-meet
  rm -rf node_modules
  rm -rf package-lock.json
  if [ ! -d .git ]; then
    git add .
    git commit -m "committing changes before switching branches"
    git clone github-trs-jitsi-meet:TheRealStart/jitsi-meet.git .
    git checkout "$CUSTOM_TRS_JITSI_MEET_BRANCH"
  else
    git fetch
    git add .
    git commit -m "committing changes before switching branches"
    git checkout "$CUSTOM_TRS_JITSI_MEET_BRANCH"
    git pull
  fi
  npm install
  make
  make source-package
  cd ..
  tar xf trs-jitsi-meet/jitsi-meet.tar.bz2
  docker build --tag jitsi/web:custom .
  cd ..

  cd jicofo
  echo "Getting latest custom jicofo codebase"
  if [ ! -d "trs-jicofo" ]; then
    mkdir trs-jicofo
  fi
  cd trs-jicofo
  if [ ! -d .git ]; then
    git clone github-trs-jicofo:TheRealStart/jicofo.git .
    git add .
    git commit -m "commiting changes if needed"
    git checkout "$CUSTOM_TRS_JICOFO_BRANCH"
  else
    git fetch
    git add .
    git commit -m "commiting changes if needed"
    git checkout "$CUSTOM_TRS_JICOFO_BRANCH"
    git pull
  fi
  mvn package -DskipTests -Dassembly.skipAssembly=false
  cd ..
  unzip -o trs-jicofo/target/jicofo-1.1-SNAPSHOT-archive.zip
  # compiled files are located under folder: trs-jicofo/jicofo-1.1-SNAPSHOT
  echo "Building custom jicofo"
  docker build --tag jitsi/jicofo:custom .
  cd ..

  # Copying prosody moderation plugin to configs path
  if [ -d "$CONFIG" ]; then
    if [ ! -d "$CONFIG/prosody/prosody-plugins-custom" ]; then
      mkdir "$CONFIG/prosody/prosody-plugins-custom"
    fi
    if [ ! -f "$CONFIG/prosody/prosody-plugins-custom/mod_token_moderation.lua" ]; then
      cp custom/prosody-plugins-custom/mod_token_moderation.lua "$CONFIG/prosody/prosody-plugins-custom/"
    fi
  fi

  set +a
else
  echo "No $envFile file found" 1>&2
  return 1
fi
