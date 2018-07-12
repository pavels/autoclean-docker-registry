#!/bin/sh
mkdir -p /var/lib/registry/docker/registry/v2/repositories
mkdir -p /var/lib/registry/docker/registry/v2/blobs
exec /bin/registry serve /etc/docker/registry/config.yml