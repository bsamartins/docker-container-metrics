variable "TAGS" {
    default = "docker-container-metrics:latest"
}

variable "REPO" {
    default = "bsamartins/docker-container-metrics"
}

target "local" {
    dockerfile = "Docker.local.dockerfile"
    tags = ["docker-container-metrics:latest"]
    output = ["type=docker"]
}

group "linux" {
  targets = ["linux-amd64", "linux-arm64"]
}

target "test" {
    dockerfile = "Test.dockerfile"
    output = ["type=image,push=true,push-by-digest=true"]
    tags = ["${REPO}"]
}

target "release" {
    output = ["push-by-digest=true"]
}

target "linux-base" {
    dockerfile = "Docker.linux.dockerfile"
    tags = ["${TAGS}"]
    context = "."
    output = ["push-by-digest=true"]
}

target "linux-amd64" {
    inherits = ["release", "linux-base"]
    platforms = ["linux/amd64"]
    args = {
        BINARY = "./build/x86_64-unknown-linux-gnu/release/docker-container-metrics"
    }
}

target "linux-arm64" {
    inherits = ["release", "linux-base"]
    platforms = ["linux/arm64"]
    args = {
        BINARY = "./build/aarch64-unknown-linux-gnu/release/docker-container-metrics"
    }
}