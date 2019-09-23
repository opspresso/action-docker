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
```

## env

Name | Description | Default | Required
---- | ----------- | ------- | --------
USERNAME | Your Docker Hub Username. | | **Yes**
PASSWORD | Your Docker Hub Password. | | **Yes**
IMAGE_NAME | Your Docker Image name. | ${GITHUB_REPOSITORY} | No
TAG_NAME | Your Docker Tag name. | $(cat ./target/TAG_NAME) | No
LATEST | Use latest tag name. | false | No
