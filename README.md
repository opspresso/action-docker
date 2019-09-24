# Docker Push

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

      - name: Build & Push to Docker Hub
        uses: opspresso/action-docker@master
        env:
          USERNAME: ${{ secrets.DOCKER_USERNAME }}
          PASSWORD: ${{ secrets.DOCKER_PASSWORD }}
          IMAGE_NAME: "user_id/image_name"
          TAG_NAME: "v0.0.1"
          LATEST: "true"

      - name: Build & Push to AWS ECR
        uses: opspresso/action-docker@master
        with:
          args: --ecr
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          IMAGE_URI: "xxxx.dkr.ecr.us-east-1.amazonaws.com/image_name"
          TAG_NAME: "v0.0.1"
          LATEST: "true"
```

## env for docker

Name | Description | Default | Required
---- | ----------- | ------- | --------
USERNAME | Your Docker Hub Username. | | **Yes**
PASSWORD | Your Docker Hub Password. | | **Yes**
IMAGE_NAME | Your Docker Image name. | ${GITHUB_REPOSITORY} | No
TAG_NAME | Your Docker Tag name. | $(cat ./target/TAG_NAME) | No
LATEST | Use latest tag name. | false | No

## env for ecr

Name | Description | Default | Required
---- | ----------- | ------- | --------
AWS_ACCESS_KEY_ID | Your AWS Access Key. | | **Yes**
AWS_SECRET_ACCESS_KEY | Your AWS Secret Access Key. | | **Yes**
AWS_ACCOUNT_ID | Your AWS Account ID. | $(aws sts get-caller-identity) | No
AWS_REGION | Your AWS Region. | us-east-1 | No
IMAGE_NAME | Your Docker Image name. | ${GITHUB_REPOSITORY} | No
TAG_NAME | Your Docker Tag name. | $(cat ./target/TAG_NAME) | No
LATEST | Use latest tag name. | false | No
