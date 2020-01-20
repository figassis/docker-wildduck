#!/bin/bash
tag="0.0.6"
docker build --rm -t figassis/wildduck:$tag . && docker push figassis/wildduck:$tag
