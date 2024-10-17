FROM scratch
EXPOSE 9000
ADD --chmod=0777 docker-container-metrics docker-container-metrics
ENTRYPOINT ["./docker-container-metrics"]