#!/bin/bash
envFile=".env"

set -a && source $envFile && docker-compose -f docker-compose-custom.yml -f jigasi.yml up -d
