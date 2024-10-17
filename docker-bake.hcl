variable "TAGS" {
    default = "bsamartins/docker-container-metrics:latest"
}

group "linux" {
  targets = ["linux-amd64", "linux-arm64"]
}

target "release" {
    output = ["type=image,push=true,push-by-digest=true"]
    tags = ["${TAGS}"]
}

target "linux-base" {
    dockerfile = "Docker.linux.dockerfile"
    context = "."
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

target "test" {
    dockerfile = "Docker.test.dockerfile"
    context = "."
    platforms = ["linux/arm64", "linux/amd64"]
    tags = ["${TAGS}"]
}