FROM scratch

ARG TARGETARCH

EXPOSE 9000
COPY --chmod=0777 ./artifacts/docker-container-metrics_$TARGETARCH docker-container-metrics
ENTRYPOINT ["./docker-container-metrics"]