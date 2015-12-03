#!/bin/bash

set -e

PREFIX=gitlab
HTTP_PORT=10080
SSH_PORT=10022
SECRET_KEY=longAndRandomAlphaNumericString
EXPOSE_HTTP_PORT=true
START_WITH_DOCKER=false

# ------------------------------------------------------

cd `dirname $0`

# override with local config
if [[ -f "$PWD/config" ]]; then
  source $PWD/config
fi

# ------------------------------------------------------

# delete all existing container if any

if [[ "`docker ps -aq --filter="name=$PREFIX-app"`" != "" ]]; then
  echo "Removing existing $PREFIX-app container."
  docker rm -f $PREFIX-app > /dev/null
fi
if [[ "`docker ps -aq --filter="name=$PREFIX-postgresql"`" != "" ]]; then
  echo "Removing existing $PREFIX-postgresql container."
  docker rm -f $PREFIX-postgresql > /dev/null
fi
if [[ "`docker ps -aq --filter="name=$PREFIX-redis"`" != "" ]]; then
  echo "Removing existing $PREFIX-redis container."
  docker rm -f $PREFIX-redis > /dev/null
fi
if [[ "$START_WITH_DOCKER" = true ]]; then
  START_WITH_DOCKER_CMD="--restart=always"
fi

# ------------------------------------------------------
# postgresql

echo "Starting $PREFIX-postgresql."

POSTGRESQL_CMD="
  docker run -d
    $START_WITH_DOCKER_CMD
    --name $PREFIX-postgresql
    --env "DB_NAME=gitlabhq_production"
    --env "DB_USER=gitlab"
    --env "DB_PASS=password"
    --volume $PWD/data/postgresql:/var/lib/postgresql
    sameersbn/postgresql:9.4-8
"

$POSTGRESQL_CMD > /dev/null

# ------------------------------------------------------
# radis

echo "Starting $PREFIX-redis."

REDIS_CMD="
  docker run -d
    $START_WITH_DOCKER_CMD
    --name $PREFIX-redis
    --volume $PWD/data/redis:/var/lib/redis
    sameersbn/redis:latest
"

$REDIS_CMD > /dev/null

# ------------------------------------------------------
# gitlab

echo "Starting $PREFIX-app."

if [[ "$EXPOSE_HTTP_PORT" = true ]]; then
  EXPOSE_HTTP_PORT_CODE="--publish $HTTP_PORT:80 --env "GITLAB_PORT=$HTTP_PORT""
fi

GITLAB_CMD="
  docker run -d
    $START_WITH_DOCKER_CMD
    $EXPOSE_HTTP_PORT_CODE
    --name $PREFIX-app
    --link $PREFIX-postgresql:postgresql
    --link $PREFIX-redis:redisio
    --publish $SSH_PORT:22
    --env "GITLAB_SSH_PORT=$SSH_PORT"
    --env "GITLAB_SECRETS_DB_KEY_BASE=$SECRET_KEY"
    --volume $PWD/data/gitlab:/home/git/data
    $GITLAB_OPTIONS
    sameersbn/gitlab:8.2.2
"

$GITLAB_CMD > /dev/null

# ------------------------------------------------------

IP=`ip route get 1 | awk '{print $NF;exit}'`

if [[ "$EXPOSE_HTTP_PORT" = true ]]; then
  echo "- Gitlab is now available at http://$IP:$HTTP_PORT/ and ssh on port $SSH_PORT."
else
  echo "- Gitlab is now available internally at http://$PREFIX-app:80/ and ssh on port $SSH_PORT."
fi

echo "- For default user and password, please see at https://github.com/sameersbn/docker-gitlab#quick-start"
