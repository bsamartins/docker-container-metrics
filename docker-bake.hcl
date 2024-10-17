variable "TAGS" {
    default = "bsamartins/docker-container-metrics:latest"
}

target "linux" {
    dockerfile = "Docker.linux.dockerfile"
    context = "."
    platforms = ["linux/arm64", "linux/amd64"]
    tags = ["${TAGS}"]
}