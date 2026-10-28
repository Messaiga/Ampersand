# Name: ampersand
# Ampersand: an opinionated custom image of Project Bluefin.
# One Containerfile builds both variants; the base image is a build argument:
#   ampersand    <- ghcr.io/ublue-os/bluefin:stable
#   ampersand-dx <- ghcr.io/ublue-os/bluefin-dx:stable
ARG BASE_IMAGE=ghcr.io/ublue-os/bluefin
ARG BASE_TAG=stable

# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files
COPY custom /custom

# Base Image
FROM ${BASE_IMAGE}:${BASE_TAG}

# Re-declare so the value is visible inside this stage (used by build scripts
# to tell the variants apart).
ARG IMAGE_NAME=ampersand

### MODIFICATIONS
## All changes happen in build_files/build.sh (see that file for the order).

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    IMAGE_NAME="${IMAGE_NAME}" /ctx/build.sh

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
