#!/usr/bin/env bash

MINIO_ROOT_USER=minioadminuser
MINIO_ROOT_PASSWORD=minioadminuser
MINIOSECRETKEY=miniosecretkey
LOCALHOSTNAME=`hostname`

brew install minio
brew install minio-mc

chmod -x ./0-minio-mac.sh
