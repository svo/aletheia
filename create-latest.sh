#!/usr/bin/env bash

image=$1

docker manifest rm "svanosselaer/aletheia-${image}:latest" 2>/dev/null || true

docker manifest create \
  "svanosselaer/aletheia-${image}:latest" \
  --amend "svanosselaer/aletheia-${image}:amd64" \
  --amend "svanosselaer/aletheia-${image}:arm64" &&
docker manifest push "svanosselaer/aletheia-${image}:latest"
