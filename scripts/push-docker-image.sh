#!/bin/bash
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 163788863765.dkr.ecr.us-east-2.amazonaws.com
docker buildx build --platform linux/amd64 -t sprawl-detector .
docker tag sprawl-detector:latest 163788863765.dkr.ecr.us-east-2.amazonaws.com/sprawl-detector:latest
docker push 163788863765.dkr.ecr.us-east-2.amazonaws.com/sprawl-detector:latest
