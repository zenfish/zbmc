FROM debian:13-slim@sha256:d7e12182ce18b85b93007c1dedf31f2d29e01ccf3182cc4017c709b6259bc132

ARG QEMU_DEBIAN_VERSION
RUN apt-get update \
 && apt-get install -y --no-install-recommends qemu-system-arm="$QEMU_DEBIAN_VERSION" \
 && rm -rf /var/lib/apt/lists/*

COPY rootfs/ /
COPY manifests/ /opt/zbmc-qemu/manifests/
