#!/bin/bash

PREFIX=gitlab
HTTP_PORT=10080
SSH_PORT=10022
SECRET_KEY=long-and-random-alpha-numeric-string

# ------------------------------------------------------

cd `dirname $0`

# override with local config
if [[ -f "$PWD/config" ]]; then
  source $PWD/config
fi

# ------------------------------------------------------

# postgresql
docker run -d \
  --name $PREFIX-postgresql \
  --env "DB_NAME=gitlabhq_production" \
  --env "DB_USER=gitlab"
  --env "DB_PASS=password" \
  --volume $PWD/data/postgresql:/var/lib/postgresql \
  sameersbn/postgresql:9.4-8

# radis
docker run -d
  --name $PREFIX-redis \
  --volume $PWD/data/redis:/var/lib/redis \
  sameersbn/redis:latest

# gitlab
docker run -d
  --name $PREFIX \
  --link $PREFIX-postgresql:postgresql \
  --link $PREFIX-redis:redisio \
  --publish $SSH_PORT:22 \
  --publish $HTTP_PORT:80 \
  --env "GITLAB_PORT=$HTTP_PORT" \
  --env "GITLAB_SSH_PORT=$SSH_PORT" \
  --env "GITLAB_SECRETS_DB_KEY_BASE=$SECRET_KEY" \
  --volume $PWD/data/gitlab:/home/git/data \
  sameersbn/gitlab:8.2.2
