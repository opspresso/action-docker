# Docker Push

## Usage

```yaml
name: Docker Push

on: push

jobs:
  slack:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout
      uses: actions/checkout@v1
      with:
        fetch-depth: 1

    - name: Docker Push
      uses: opspresso/action-docker@master
      env:
        USERNAME: ${{ secrets.DOCKER_USERNAME }}
        PASSWORD: ${{ secrets.DOCKER_PASSWORD }}
        IMAGE_NAME: "image/name"
        TAG_NAME: "v0.0.1"
```

## env

Name | Description | Default | Required
---- | ----------- | ------- | --------
USERNAME | Your Docker Hub Username. | | **Yes**
PASSWORD | Your Docker Hub Password. | | **Yes**
IMAGE_NAME | Your Docker Image name. | | **Yes**
TAG_NAME | Your Docker Tag name. | | **Yes**
