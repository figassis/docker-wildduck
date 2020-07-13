#!/bin/bash
tag="0.0.10"
docker build --rm -t figassis/wildduck:$tag . && docker push figassis/wildduck:$tag
