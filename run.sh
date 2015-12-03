#!/bin/bash

PREFIX=gitlab

cd `dirname $0`

# postgresql
docker run -d \
  --name $PREFIX-postgresql \
  --env 'DB_NAME=gitlabhq_production' \
  --env 'DB_USER=gitlab'
  --env 'DB_PASS=password' \
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
  --publish 10022:22 \
  --publish 10080:80 \
  --env 'GITLAB_PORT=10080' \
  --env 'GITLAB_SSH_PORT=10022' \
  --env 'GITLAB_SECRETS_DB_KEY_BASE=long-and-random-alpha-numeric-string' \
  --volume $PWD/data/gitlab:/home/git/data \
  sameersbn/gitlab:8.2.2
