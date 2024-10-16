target "local" {
    dockerfile = "Docker.local.dockerfile"
    tags = ["docker-container-metrics:latest"]
    output = ["type=docker"]
}