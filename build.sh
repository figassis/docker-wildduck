#!/bin/bash
tag="0.0.1"
docker build --rm -t figassis/wildduck:$tag . && docker push figassis/wildduck:$tag
