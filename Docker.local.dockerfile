FROM rust:latest AS build
WORKDIR /app
ADD . .
RUN cargo build --verbose --release
RUN find .

FROM ubuntu
EXPOSE 9000
COPY --from=build --chmod=0777 /app/target/release/docker-container-metrics docker-container-metrics
RUN ls -la
ENTRYPOINT ["./docker-container-metrics"]