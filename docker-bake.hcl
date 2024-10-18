variable "TAGS" {
    default = "bsamartins/docker-container-metrics:latest"
}

target "local" {
    dockerfile = "Docker.local.dockerfile"
    context = "."
    tags = ["${TAGS}"]
    output = ["type=image"]
}

target "linux" {
    dockerfile = "Docker.linux.dockerfile"
    context = "."
    platforms = ["linux/arm64", "linux/amd64"]
    tags = ["${TAGS}"]
}