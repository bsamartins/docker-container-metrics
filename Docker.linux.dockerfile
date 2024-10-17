FROM rust:latest AS build
WORKDIR /app
ADD . .
RUN cargo build --verbose --release
RUN find .

FROM scratch
EXPOSE 9000
COPY --from=build --chmod=0777 /app/target/release/docker-container-metrics docker-container-metrics
ENTRYPOINT ["./docker-container-metrics"]