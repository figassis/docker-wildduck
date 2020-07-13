#!/bin/bash
docker-compose down -f --remove-orphans; docker-compose build && docker-compose up -d