# syntax=docker/dockerfile:1
FROM --platform=$BUILDPLATFORM tonistiigi/xx AS xx

FROM --platform=$BUILDPLATFORM rust:1.74-alpine AS base

RUN apk update && \
    apk add \
        gcc \
        g++ \
        clang

COPY --from=xx / /

ARG TARGETPLATFORM
RUN xx-info env

RUN xx-apk add \
    gcc \
    musl-dev \
    libdeflate

WORKDIR /src

COPY . .

RUN --mount=type=cache,target=/root/.cargo/git/db \
    --mount=type=cache,target=/root/.cargo/registry/cache \
    --mount=type=cache,target=/root/.cargo/registry/index \
    xx-cargo build --release && \
    xx-verify /src/target/$(xx-cargo --print-target-triple)/release/oxipng && \
    cp /src/target/$(xx-cargo --print-target-triple)/release/oxipng /src/target/oxipng

FROM alpine AS tool

LABEL org.opencontainers.image.title="Oxipng"
LABEL org.opencontainers.image.description="Multithreaded PNG optimizer written in Rust"
LABEL org.opencontainers.image.authors="Joshua Holmer <jholmer.in@gmail.com>"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.source="https://github.com/shssoichiro/oxipng"

COPY --from=base /src/target/oxipng /usr/local/bin

WORKDIR /work
ENTRYPOINT [ "oxipng" ]
CMD [ "--help" ]
