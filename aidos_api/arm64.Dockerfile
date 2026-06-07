FROM --platform=linux/arm64 alpine:latest
RUN apk add --no-cache build-base cmake git linux-headers
WORKDIR /workspace
