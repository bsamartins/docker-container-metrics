target "local" {
    dockerfile = "Docker.local.dockerfile"
    tags = ["docker-container-metrics:latest"]
    output = ["type=docker"]
}

target "linux-runtime" {
    dockerfile = "Docker.linux.dockerfile"
    tags = ["docker-container-metrics:latest"]
}