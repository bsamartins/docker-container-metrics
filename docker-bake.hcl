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
}

target "linux-amd64" {
    inherits = ["linux-base"]
    platforms = ["linux/amd64"]
    args = {
        BINARY = "target/release/x86_64-unknown-linux-gnu/docker-container-metrics"
    }
}

target "linux-arm64" {
    inherits = ["linux-base"]
    platforms = ["linux/arm64"]
    args = {
        BINARY = "target/release/aarch64-unknown-linux-gnu/docker-container-metrics"
    }
}