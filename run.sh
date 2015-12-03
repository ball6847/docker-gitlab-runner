#!/bin/bash

set -e

PREFIX=gitlab
HTTP_PORT=10080
SSH_PORT=10022
SECRET_KEY=longAndRandomAlphaNumericString

# ------------------------------------------------------

cd `dirname $0`

# override with local config
if [[ -f "$PWD/config" ]]; then
  source $PWD/config
fi

# ------------------------------------------------------

# delete all existing container if any

if [[ "`docker ps -aq --filter="name=$PREFIX-app"`" != "" ]]; then
  echo "Removing existing $PREFIX container."
  docker rm -f $PREFIX > /dev/null
fi
if [[ "`docker ps -aq --filter="name=$PREFIX-postgresql"`" != "" ]]; then
  echo "Removing existing $PREFIX-postgresql container."
  docker rm -f $PREFIX-postgresql > /dev/null
fi
if [[ "`docker ps -aq --filter="name=$PREFIX-redis"`" != "" ]]; then
  echo "Removing existing $PREFIX-redis container."
  docker rm -f $PREFIX-redis > /dev/null
fi

# ------------------------------------------------------

# postgresql
echo "Starting $PREFIX-postgresql."
docker run -d \
  --name $PREFIX-postgresql \
  --env "DB_NAME=gitlabhq_production" \
  --env "DB_USER=gitlab" \
  --env "DB_PASS=password" \
  --volume $PWD/data/postgresql:/var/lib/postgresql \
  sameersbn/postgresql:9.4-8 > /dev/null

# radis
echo "Starting $PREFIX-redis."
docker run -d \
  --name $PREFIX-redis \
  --volume $PWD/data/redis:/var/lib/redis \
  sameersbn/redis:latest > /dev/null

# gitlab
echo "Starting $PREFIX."
docker run -d \
  --name $PREFIX-app \
  --link $PREFIX-postgresql:postgresql \
  --link $PREFIX-redis:redisio \
  --publish $SSH_PORT:22 \
  --publish $HTTP_PORT:80 \
  --env "GITLAB_PORT=$HTTP_PORT" \
  --env "GITLAB_SSH_PORT=$SSH_PORT" \
  --env "GITLAB_SECRETS_DB_KEY_BASE=$SECRET_KEY" \
  --volume $PWD/data/gitlab:/home/git/data \
  sameersbn/gitlab:8.2.2 > /dev/null

IP=`ip route get 1 | awk '{print $NF;exit}'`

echo "-- Gitlab is now available at http://$IP:$HTTP_PORT/ and ssh on port $SSH_PORT."
echo "-- For default user and password, please see at https://github.com/sameersbn/docker-gitlab#quick-start"
