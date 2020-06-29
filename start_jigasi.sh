#!/bin/bash
envFile=".env"

set -a && source $envFile && docker-compose -f jigasi.yml up -d

# Restart other jitsi docker containers 
# for environment variables to pass in
docker-compose -f docker-compose-custom.yml up -d