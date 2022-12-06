#!/bin/bash
DOCKER_IMAGE=ghcr.io/coqui-ai/tts:main
docker run --rm -it -p 5002:5002 --gpus all --entrypoint /bin/bash "$DOCKER_IMAGE"