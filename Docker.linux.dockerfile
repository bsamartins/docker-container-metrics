FROM scratch

ARG BINARY

EXPOSE 9000
COPY --chmod=0777 $BINARY docker-container-metrics
ENTRYPOINT ["./docker-container-metrics"]