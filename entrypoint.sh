#!/bin/sh

CMD="$1"

_error() {
  echo -e "$1"

  if [ "${LOOSE_ERROR}" == "true" ]; then
    exit 0
  else
    exit 1
  fi
}

_aws_pre() {
  if [ -z "${AWS_ACCESS_KEY_ID}" ]; then
    _error "AWS_ACCESS_KEY_ID is not set."
  fi

  if [ -z "${AWS_SECRET_ACCESS_KEY}" ]; then
    _error "AWS_SECRET_ACCESS_KEY is not set."
  fi

  if [ -z "${AWS_REGION}" ]; then
    AWS_REGION="us-east-1"
  fi
}

_ecr_pre() {
  _aws_pre

  if [ -z "${AWS_ACCOUNT_ID}" ]; then
    AWS_ACCOUNT_ID="$(aws sts get-caller-identity | grep "Account" | cut -d'"' -f4)"
  fi

  if [ -z "${IMAGE_NAME}" ]; then
    IMAGE_NAME="${GITHUB_REPOSITORY}"
  fi

  if [ -z "${IMAGE_URI}" ]; then
    IMAGE_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${IMAGE_NAME}"
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

_ecr() {
  _ecr_pre

  # aws credentials
  aws configure <<-EOF > /dev/null 2>&1
${AWS_ACCESS_KEY_ID}
${AWS_SECRET_ACCESS_KEY}
${AWS_REGION}
text
EOF

  echo "aws ecr get-login --no-include-email"
  aws ecr get-login --no-include-email | sh

  echo "docker build -t ${IMAGE_URI}:${TAG_NAME} ."
  docker build -t ${IMAGE_URI}:${TAG_NAME} .

  echo "docker push ${IMAGE_URI}:${TAG_NAME}"
  docker push ${IMAGE_URI}:${TAG_NAME}

  if [ "${LATEST}" == "true" ]; then
    echo "docker tag ${IMAGE_URI}:latest"
    docker tag ${IMAGE_URI}:${TAG_NAME} ${IMAGE_URI}:latest

    echo "docker push ${IMAGE_URI}:latest"
    docker push ${IMAGE_URI}:latest
  fi

  # echo "docker logout"
  # docker logout
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

if [ -z "${CMD}" ]; then
  CMD="--docker"
fi

echo "[${CMD:2}] start..."

case "${CMD:2}" in
  docker)
    _docker
    ;;
  ecr)
    _ecr
    ;;
  *)
    _error
esac
