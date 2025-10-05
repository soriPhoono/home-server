#!/usr/bin/env bash

docker swarm init --advertise-addr 192.168.0.21

docker network create -d overlay traefik_public

docker stack deploy server -c ./server/docker-compose.yml