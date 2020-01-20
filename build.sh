#!/bin/bash
tag="0.0.7"
docker build --rm -t figassis/wildduck:$tag . && docker push figassis/wildduck:$tag
