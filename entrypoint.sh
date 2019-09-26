#!/bin/sh

CMD="$1"

REPOSITORY=${GITHUB_REPOSITORY}

USERNAME=${USERNAME:-$GITHUB_ACTOR}
REPONAME=$(echo "${REPOSITORY}" | cut -d'/' -f2)

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

_docker_tag() {
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

_docker_image_uri_tag() {
  if [ "${REGISTRY}" == "docker.pkg.github.com" ]; then
    printf "${IMAGE_URI}/${1}"
  else
    printf "${IMAGE_URI}:${1}"
  fi
}

_docker_push() {
  IMAGE_URI_TAG="$(_docker_image_uri_tag ${TAG_NAME})"

  echo "docker build -t ${IMAGE_URI_TAG} ."
  docker build -t ${IMAGE_URI_TAG} .

  echo "docker push ${IMAGE_URI_TAG}"
  docker push ${IMAGE_URI_TAG}

  if [ "${LATEST}" == "true" ]; then
    IMAGE_URI_LATEST="$(_docker_image_uri_tag latest)"

    echo "docker tag ${IMAGE_URI_LATEST}"
    docker tag ${IMAGE_URI_TAG} ${IMAGE_URI_LATEST}

    echo "docker push ${IMAGE_URI_LATEST}"
    docker push ${IMAGE_URI_LATEST}
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

  if [ -z "${IMAGE_URI}" ]; then
    if [ -z "${REGISTRY}" ]; then
      IMAGE_URI="${IMAGE_NAME}"
    else
      IMAGE_URI="${REGISTRY}/${IMAGE_NAME}"
    fi
  fi

  _docker_tag
}

_docker() {
  _docker_pre

  echo "docker login ${REGISTRY} -u ${USERNAME}"
  echo ${PASSWORD} | docker login ${REGISTRY} -u ${USERNAME} --password-stdin

  _docker_push

  echo "docker logout"
  docker logout
}

_docker_ecr_pre() {
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

  _docker_tag

  if [ "${IMAGE_TAG_MUTABILITY}" != "IMMUTABLE" ]; then
    IMAGE_TAG_MUTABILITY="MUTABLE"
  fi
}

_docker_ecr() {
  _docker_ecr_pre

  # aws credentials
  aws configure <<-EOF > /dev/null 2>&1
${AWS_ACCESS_KEY_ID}
${AWS_SECRET_ACCESS_KEY}
${AWS_REGION}
text
EOF

  echo "aws ecr get-login --no-include-email"
  aws ecr get-login --no-include-email | sh

  COUNT=$(aws ecr describe-repositories | jq '.repositories[] | .repositoryName' | grep "\"${IMAGE_NAME}\"" | wc -l | xargs)
  if [ "x${COUNT}" == "x0" ]; then
    echo "aws ecr create-repository ${IMAGE_NAME}"
    aws ecr create-repository --repository-name ${IMAGE_NAME} --image-tag-mutability ${IMAGE_TAG_MUTABILITY}
  fi

  _docker_push
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
    _docker_ecr
    ;;
  *)
    _error
esac
