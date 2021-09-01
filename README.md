# Docker Push Action

[![GitHub Actions status](https://github.com/opspresso/action-docker/workflows/Build-Push/badge.svg)](https://github.com/opspresso/action-docker/actions)
[![GitHub Releases](https://img.shields.io/github/release/opspresso/action-docker.svg)](https://github.com/opspresso/action-docker/releases)

## Usage

```yaml
name: Docker Push

on: push

jobs:
  docker:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v1
        with:
          fetch-depth: 1

      - name: Docker Build & Push to Docker Hub
        uses: opspresso/action-docker@master
        with:
          args: --docker
        env:
          USERNAME: ${{ secrets.DOCKER_USERNAME }}
          PASSWORD: ${{ secrets.DOCKER_PASSWORD }}
          DOCKERFILE: "Dockerfile"
          IMAGE_NAME: "USERNAME/IMAGE_NAME"
          TAG_NAME: "v0.0.1"
          LATEST: "true"
          BUILDX: "true"

      - name: Docker Build & Push to GitHub Package
        uses: opspresso/action-docker@master
        with:
          args: --docker
        env:
          USERNAME: ${{ secrets.GITHUB_USERNAME }}
          PASSWORD: ${{ secrets.GH_PERSONAL_TOKEN }}
          REGISTRY: "docker.pkg.github.com"
          DOCKERFILE: "Dockerfile"
          IMAGE_NAME: "IMAGE_NAME"
          TAG_NAME: "v0.0.1"
          LATEST: "true"

      - name: Docker Build & Push to AWS ECR
        uses: opspresso/action-docker@master
        with:
          args: --ecr
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          IMAGE_URI: "xxxx.dkr.ecr.us-east-1.amazonaws.com/IMAGE_NAME"
          DOCKERFILE: "Dockerfile.aws"
          TAG_NAME: "v0.0.1"
          LATEST: "true"
          BUILDX: "true"
```

## Common env

Name | Description | Default | Required
---- | ----------- | ------- | --------
BUILD_PATH | The path where the Dockerfile. | . | No
DOCKER_BUILD_ARGS | Build args passed to Docker. | | No
DOCKERFILE | The Dockerfile name. | Dockerfile | No
IMAGE_NAME | Your Docker Image name. | ${GITHUB_REPOSITORY} | No
TAG_NAME | Your Docker Tag name. | $(cat ./target/TAG_NAME) if the file exists, or `latest` instead | No
LATEST | Use latest tag name. | false | No

## env for Docker Hub

Name | Description | Default | Required
---- | ----------- | ------- | --------
USERNAME | Your Docker Hub Username. | ${GITHUB_ACTOR} | No
PASSWORD | Your Docker Hub Password. | | **Yes**
REGISTRY | Your Docker Registry Uri. | | No

## env for AWS ECR

Name | Description | Default | Required
---- | ----------- | ------- | --------
AWS_ACCESS_KEY_ID | Your AWS Access Key. | | **Yes**
AWS_SECRET_ACCESS_KEY | Your AWS Secret Access Key. | | **Yes**
AWS_REGION | Your AWS Region. | us-east-1 | No
AWS_ACCOUNT_ID | Your AWS Account ID. | $(aws sts get-caller-identity) | No
IMAGE_URI | Your Docker Image uri. | ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${IMAGE_NAME} | No
IMAGE_TAG_MUTABILITY | The tag mutability setting for the repository. | MUTABLE | No
