#!/bin/sh

CMD="$1"

REPOSITORY=${GITHUB_REPOSITORY}

USERNAME=${USERNAME:-$GITHUB_ACTOR}
REPONAME=$(echo "${REPOSITORY}" | cut -d'/' -f2)

command -v tput >/dev/null && TPUT=true

_echo() {
  if [ "${TPUT}" != "" ] && [ "$2" != "" ]; then
    echo -e "$(tput setaf $2)$1$(tput sgr0)"
  else
    echo -e "$1"
  fi
}

_result() {
  echo
  _echo "# $@" 4
}

_command() {
  echo
  _echo "$ $@" 3
}

_success() {
  echo
  _echo "+ $@" 2
  exit 0
}

_error() {
  echo
  _echo "- $@" 1
  if [ "${LOOSE_ERROR}" == "true" ]; then
    exit 0
  else
    exit 1
  fi
}

_error_check() {
  RESULT=$?

  if [ ${RESULT} != 0 ]; then
    _error ${RESULT}
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
  if [ ! -z "${TAG_NAME}" ]; then
    TAG_NAME=${TAG_NAME##*/}
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
      TAG_NAME="latest"
    fi
  fi

  if [ ! -z "${TAG_POST}" ]; then
    TAG_NAME="${TAG_NAME}-${TAG_POST}"
  fi
}

_docker_file() {
  if [ -z "${DOCKERFILE}" ]; then
    DOCKERFILE="Dockerfile"
    if [ ! -f ${DOCKERFILE} ]; then
      if [ ! -z "${BASE_IMAGE}" ]; then
        echo "FROM ${BASE_IMAGE}:${TAG_NAME}" >${DOCKERFILE}
      else
        _error "${DOCKERFILE} not found."
      fi
    fi
  fi
}

_docker_build() {
  _command "docker build ${DOCKER_BUILD_ARGS} -t ${IMAGE_URI}:${TAG_NAME} -f ${DOCKERFILE} ${BUILD_PATH}"
  docker build ${DOCKER_BUILD_ARGS} -t ${IMAGE_URI}:${TAG_NAME} -f ${DOCKERFILE} ${BUILD_PATH}

  _error_check

  _command "docker push ${IMAGE_URI}:${TAG_NAME}"
  docker push ${IMAGE_URI}:${TAG_NAME}

  _error_check

  if [ "${LATEST}" == "true" ]; then
    _command "docker tag ${IMAGE_URI}:latest"
    docker tag ${IMAGE_URI}:${TAG_NAME} ${IMAGE_URI}:latest

    _command "docker push ${IMAGE_URI}:latest"
    docker push ${IMAGE_URI}:latest
  fi
}

# _docker_builds() {
#   TAG_NAMES=""

#   ARR=(${PLATFORM//,/ })

#   for V in ${ARR[@]}; do
#       P="${V//\//-}"

#       _command "docker build ${DOCKER_BUILD_ARGS} --build-arg ARCH=${V} -t ${IMAGE_URI}:${TAG_NAME}-${P} -f ${DOCKERFILE} ${BUILD_PATH}"
#       docker build ${DOCKER_BUILD_ARGS} --build-arg ARCH=${V} -t ${IMAGE_URI}:${TAG_NAME}-${P} -f ${DOCKERFILE} ${BUILD_PATH}

#       _error_check

#       _command "docker push ${IMAGE_URI}:${TAG_NAME}-${P}"
#       docker push ${IMAGE_URI}:${TAG_NAME}-${P}

#       _error_check

#       TAG_NAMES="${TAG_NAMES} -a ${IMAGE_URI}:${TAG_NAME}-${P}"
#   done

#   _docker_manifest ${IMAGE_URI}:${TAG_NAME} ${TAG_NAMES}

#   # if [ "${LATEST}" == "true" ]; then
#   #   _docker_manifest ${IMAGE_URI}:latest -a ${TAG_NAMES}
#   # fi
# }

_docker_manifest() {
  _command "docker manifest create ${@}"
  docker manifest create ${@}

  _error_check

  _command "docker manifest inspect ${1}"
  docker manifest inspect ${1}

  _command "docker manifest push ${1}"
  docker manifest push ${1}
}

_docker_buildx() {
  if [ -z "${PLATFORM}" ]; then
    PLATFORM="linux/arm64,linux/amd64"
  fi

  PLACE=$(date +%s)

  _command "docker buildx create --use --name ops-${PLACE}"
  docker buildx create --use --name ops-${PLACE}

  _command "docker buildx build ${DOCKER_BUILD_ARGS} -t ${IMAGE_URI}:${TAG_NAME} -f ${DOCKERFILE} ${BUILD_PATH}"
  docker buildx build --push ${DOCKER_BUILD_ARGS} -t ${IMAGE_URI}:${TAG_NAME} -f ${DOCKERFILE} ${BUILD_PATH} --platform ${PLATFORM}

  _error_check

  _command "docker buildx imagetools inspect ${IMAGE_URI}:${TAG_NAME}"
  docker buildx imagetools inspect ${IMAGE_URI}:${TAG_NAME}

  # if [ "${LATEST}" == "true" ]; then
  #   _docker_manifest ${IMAGE_URI}:latest -a ${IMAGE_URI}:${TAG_NAME}
  # fi
}

_docker_pre() {
  _docker_tag

  if [ -z "${USERNAME}" ]; then
    _error "USERNAME is not set."
  fi

  if [ -z "${PASSWORD}" ]; then
    _error "PASSWORD is not set."
  fi

  if [ -z "${BUILD_PATH}" ]; then
    BUILD_PATH="."
  fi

  _docker_file

  if [ -z "${IMAGE_NAME}" ]; then
    if [ "${REGISTRY}" == "docker.pkg.github.com" ]; then
      IMAGE_NAME="${REPONAME}"
    else
      IMAGE_NAME="${REPOSITORY}"
    fi
  fi

  if [ -z "${IMAGE_URI}" ]; then
    if [ -z "${REGISTRY}" ]; then
      IMAGE_URI="${IMAGE_NAME}"
    elif [ "${REGISTRY}" == "docker.pkg.github.com" ]; then
      # :owner/:repo_name/:image_name
      IMAGE_URI="${REGISTRY}/${REPOSITORY}/${IMAGE_NAME}"
    else
      IMAGE_URI="${REGISTRY}/${IMAGE_NAME}"
    fi
  fi
}

_docker() {
  _docker_pre

  _command "docker login ${REGISTRY} -u ${USERNAME}"
  echo ${PASSWORD} | docker login ${REGISTRY} -u ${USERNAME} --password-stdin

  _error_check

  if [ "${BUILDX}" == "true" ]; then
    _docker_buildx
  else
    _docker_build
    # if [ "${PLATFORM}" == "" ]; then
    #   _docker_build
    # else
    #   _docker_builds
    # fi
  fi

  _command "docker logout"
  docker logout
}

_docker_ecr_pre() {
  _aws_pre

  _docker_tag

  if [ -z "${AWS_ACCOUNT_ID}" ]; then
    AWS_ACCOUNT_ID="$(aws sts get-caller-identity --output json | jq '.Account' -r)"
  fi

  if [ -z "${BUILD_PATH}" ]; then
    BUILD_PATH="."
  fi

  _docker_file

  if [ -z "${REGISTRY}" ]; then
    REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
  fi

  PUBLIC=$(echo ${REGISTRY} | cut -d'.' -f1)

  if [ -z "${IMAGE_NAME}" ]; then
    if [ "${PUBLIC}" == "public" ]; then
      IMAGE_NAME="${REPONAME}"
    else
      IMAGE_NAME="${REPOSITORY}"
    fi
  fi

  if [ -z "${IMAGE_URI}" ]; then
    IMAGE_URI="${REGISTRY}/${IMAGE_NAME}"
  fi

  if [ "${IMAGE_TAG_MUTABILITY}" != "IMMUTABLE" ]; then
    IMAGE_TAG_MUTABILITY="MUTABLE"
  fi
}

_docker_ecr() {
  _docker_ecr_pre

  # aws credentials
  aws configure <<-EOF >/dev/null 2>&1
${AWS_ACCESS_KEY_ID}
${AWS_SECRET_ACCESS_KEY}
${AWS_REGION}
text
EOF

  if [ "${PUBLIC}" == "public" ]; then
    _command "aws ecr-public get-login-password --region us-east-1 ${REGISTRY}"
    aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${REGISTRY}
  else
    _command "aws ecr get-login-password --region ${AWS_REGION} ${REGISTRY}"
    aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${REGISTRY}
  fi

  _error_check

  if [ "${PUBLIC}" == "public" ]; then
    COUNT=$(aws ecr-public describe-repositories --region us-east-1 --output json | jq '.repositories[] | .repositoryName' | grep "\"${IMAGE_NAME}\"" | wc -l | xargs)
    if [ "x${COUNT}" == "x0" ]; then
      _command "aws ecr-public create-repository ${IMAGE_NAME}"
      aws ecr-public create-repository --repository-name ${IMAGE_NAME} --region us-east-1
    fi
  else
    COUNT=$(aws ecr describe-repositories --output json | jq '.repositories[] | .repositoryName' | grep "\"${IMAGE_NAME}\"" | wc -l | xargs)
    if [ "x${COUNT}" == "x0" ]; then
      _command "aws ecr create-repository ${IMAGE_NAME}"
      aws ecr create-repository --repository-name ${IMAGE_NAME} --image-tag-mutability ${IMAGE_TAG_MUTABILITY}
    fi
  fi

  if [ "${BUILDX}" == "true" ]; then
    _docker_buildx
  else
    _docker_build
    # if [ "${PLATFORM}" == "" ]; then
    #   _docker_build
    # else
    #   _docker_builds
    # fi
  fi
}

if [ -z "${CMD}" ]; then
  CMD="--docker"
fi

_result "[${CMD:2}] start..."

case "${CMD:2}" in
docker)
  _docker
  ;;
ecr)
  _docker_ecr
  ;;
*)
  _error
  ;;
esac

echo ::set-output name=TAG_NAME::${TAG_NAME}
