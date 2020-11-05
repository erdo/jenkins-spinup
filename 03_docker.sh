#!/bin/bash

#
# This script has been tested to run on Ubuntu Server 18.04
#
# It is not intended to be run manually (it's invoked by a different script)
#
# Head over to the README for detailed instructions
#

echo "running 03_docker.sh";

# remove everything we can, all docker images etc - helpful during development to prevent us running out of space or using stale code
# docker stop $(docker ps -qa); docker rm $(docker ps -qa); docker rmi -f $(docker images -qa); docker volume rm $(docker volume ls -q); docker network rm $(docker network ls -q)

sudo systemctl start docker;

docker-compose build --no-cache;

docker-compose up -d;
