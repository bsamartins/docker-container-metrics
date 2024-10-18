FROM rust:latest AS build
WORKDIR /app
ADD . .

ENV CARGO_TARGET_AARCH64_UNKNOWN_LINUX_MUSL_LINKER=aarch64-linux-gnu-gcc
ENV CC=aarch64-linux-gnu-gcc

RUN rustup target add aarch64-unknown-linux-musl
RUN cargo build --verbose --release --target aarch64-unknown-linux-musl
RUN cp /app/target/aarch64-unknown-linux-musl/release/docker-container-metrics /app/target/release/docker-container-metrics

FROM alpine

EXPOSE 9000
COPY --from=build --chmod=0777 /app/target/release/docker-container-metrics docker-container-metrics

ENTRYPOINT ["./docker-container-metrics"]