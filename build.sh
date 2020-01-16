#!/bin/bash
tag="0.0.1"
docker build --rm -t figassis/docker-wildduck:$tag . && docker push figassis/docker-wildduck:$tag
