#!/bin/bash

envFile=".env"

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
  if [ ! -d .git ]; then
    git clone github-trs-jitsi-meet:TheRealStart/jitsi-meet.git .
    git checkout "$CUSTOM_TRS_JITSI_MEET_BRANCH"
  else
    git fetch
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

  docker-compose -f fiesta_web.yml up -d
fi