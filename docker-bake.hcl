variable "TAGS" {
    default = "bsamartins/docker-container-metrics:latest"
}

target "local" {
    dockerfile = "Docker.local.dockerfile"
    context = "."
    tags = ["docker-container-metrics"]
    output = ["type=docker"]
}

target "linux" {
    dockerfile = "Docker.linux.dockerfile"
    context = "."
    platforms = ["linux/arm64", "linux/amd64"]
    tags = ["${TAGS}"]
}