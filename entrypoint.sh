#!/bin/sh

set -e

_docker_pre() {
  if [ -z "${USERNAME}" ]; then
    echo "DOCKER_USER is not set."
    exit 1
  fi

  if [ -z "${PASSWORD}" ]; then
    echo "PASSWORD is not set."
    exit 1
  fi

  if [ -z "${IMAGE_NAME}" ]; then
    echo "IMAGE_NAME is not set."
    exit 1
  fi

  if [ -z "${TAG_NAME}" ]; then
    echo "TAG_NAME is not set."
    exit 1
  fi
}

_docker() {
    _docker_pre

    _command "docker login -u ${USERNAME}"
    docker login -u ${USERNAME} -p ${PASSWORD}

    _command "docker build -t ${IMAGE_NAME}:${TAG_NAME} ."
    docker build -t ${IMAGE_NAME}:${TAG_NAME} .

    _command "docker push ${IMAGE_NAME}:${TAG_NAME}"
    docker push ${IMAGE_NAME}:${TAG_NAME}

    _command "docker logout"
    docker logout
}

_docker
