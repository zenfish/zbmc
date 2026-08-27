FROM debian:13-slim

ARG QEMU_DEBIAN_VERSION
RUN apt-get update \
 && apt-get install -y --no-install-recommends qemu-system-arm="$QEMU_DEBIAN_VERSION" \
 && rm -rf /var/lib/apt/lists/*

COPY rootfs/ /
COPY manifests/ /opt/zbmc-qemu/manifests/
