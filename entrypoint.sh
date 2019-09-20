#!/bin/sh

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
    if [ -f ./target/TAG_NAME ]; then
      TAG_NAME=$(cat ./target/TAG_NAME | xargs)
    elif [ -f ./target/VERSION ]; then
      TAG_NAME=$(cat ./target/VERSION | xargs)
    elif [ -f ./VERSION ]; then
      TAG_NAME=$(cat ./VERSION | xargs)
    fi
    if [ -z "${TAG_NAME}" ]; then
      echo "TAG_NAME is not set."
      exit 1
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

  if [ ! -z "${LATEST}" ]; then
    echo "docker tag ${IMAGE_NAME}:latest"
    docker tag ${IMAGE_NAME}:${TAG_NAME} ${IMAGE_NAME}:latest

    echo "docker push ${IMAGE_NAME}:latest"
    docker push ${IMAGE_NAME}:latest
  fi

  echo "docker logout"
  docker logout
}

_docker
