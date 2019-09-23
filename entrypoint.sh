#!/bin/sh

_error() {
  echo -e "$1"

  if [ "${LOOSE_ERROR}" == "true" ]; then
    exit 0
  else
    exit 1
  fi
}

_docker_pre() {
  if [ -z "${USERNAME}" ]; then
    _error "USERNAME is not set."
  fi

  if [ -z "${PASSWORD}" ]; then
    _error "PASSWORD is not set."
  fi

  if [ -z "${IMAGE_NAME}" ]; then
    IMAGE_NAME="${GITHUB_REPOSITORY}"
  fi

  if [ -z "${TAG_NAME}" ]; then
    if [ -f ./target/TAG_NAME ]; then
      TAG_NAME=$(cat ./target/TAG_NAME | xargs)
    elif [ -f ./target/VERSION ]; then
      TAG_NAME=$(cat ./target/VERSION | xargs)
    elif [ -f ./VERSION ]; then
      TAG_NAME=$(cat ./VERSION | xargs)
    fi
    if [ -z "${TAG_NAME}" ]; then
      _error "TAG_NAME is not set."
    fi
  fi
}

_docker() {
  _docker_pre

  echo "docker login -u ${USERNAME}"
  echo ${PASSWORD} | docker login -u ${USERNAME} --password-stdin

  echo "docker build -t ${IMAGE_NAME}:${TAG_NAME} ."
  docker build -t ${IMAGE_NAME}:${TAG_NAME} .

  echo "docker push ${IMAGE_NAME}:${TAG_NAME}"
  docker push ${IMAGE_NAME}:${TAG_NAME}

  if [ "${LATEST}" == "true" ]; then
    echo "docker tag ${IMAGE_NAME}:latest"
    docker tag ${IMAGE_NAME}:${TAG_NAME} ${IMAGE_NAME}:latest

    echo "docker push ${IMAGE_NAME}:latest"
    docker push ${IMAGE_NAME}:latest
  fi

  echo "docker logout"
  docker logout
}

_docker
