variable "TAGS" {
    default = "docker-container-metrics:latest"
}

target "local" {
    dockerfile = "Docker.local.dockerfile"
    tags = ["docker-container-metrics:latest"]
    output = ["type=docker"]
}

group "linux" {
  targets = ["linux-amd64", "linux-arm64"]
}

target "linux-base" {
    dockerfile = "Docker.linux.dockerfile"
    tags = ["${TAGS}"]
    context = "."
    output = ["push-by-digest=true"]
}

target "linux-amd64" {
    inherits = ["linux-base"]
    platforms = ["linux/amd64"]
    args = {
        BINARY = "./build/x86_64-unknown-linux-gnu/release/docker-container-metrics"
    }
}

target "linux-arm64" {
    inherits = ["linux-base"]
    platforms = ["linux/arm64"]
    args = {
        BINARY = "./build/aarch64-unknown-linux-gnu/release/docker-container-metrics"
    }
}